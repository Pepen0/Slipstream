#include "iracing_adapter_plugin.h"

#include "coordinate_normalizer.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <memory>
#include <string>
#include <utility>

#ifdef _WIN32
#define NOMINMAX
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

namespace slipstream::physics {
namespace {

constexpr int32_t kIRSDKStatusConnected = 0x1;
constexpr int32_t kIRSDKMaxBuf = 4;
constexpr int32_t kIRSDKMaxString = 32;
constexpr int32_t kIRSDKDescLen = 64;
constexpr wchar_t kIRacingMemMapName[] = L"Local\\IRSDKMemMapFileName";

enum class IRSDKVarType : int32_t {
  Char = 0,
  Bool = 1,
  Int = 2,
  BitField = 3,
  Float = 4,
  Double = 5,
};

#pragma pack(push, 1)
struct IRSDKVarBuffer {
  int32_t tick_count;
  int32_t buffer_offset;
  int32_t pad[2];
};

struct IRSDKHeader {
  int32_t version;
  int32_t status;
  int32_t tick_rate;
  int32_t session_info_update;
  int32_t session_info_len;
  int32_t session_info_offset;
  int32_t num_vars;
  int32_t var_header_offset;
  int32_t num_buf;
  int32_t buf_len;
  int32_t pad[2];
  IRSDKVarBuffer var_buffers[kIRSDKMaxBuf];
};

struct IRSDKVarHeader {
  int32_t type;
  int32_t offset;
  int32_t count;
  int32_t count_as_time;
  char name[kIRSDKMaxString];
  char desc[kIRSDKDescLen];
  char unit[kIRSDKMaxString];
};
#pragma pack(pop)

struct FieldRef {
  int32_t type = -1;
  int32_t offset = -1;
  int32_t count = 0;

  bool is_valid() const {
    return offset >= 0 && count > 0;
  }
};

uint64_t now_ns() {
  using clock = std::chrono::steady_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(clock::now().time_since_epoch()).count();
}

int32_t clamp_num_buf(int32_t num_buf) {
  if (num_buf <= 0) {
    return 0;
  }
  return std::min(num_buf, kIRSDKMaxBuf);
}

std::string c_str_copy(const char *chars, std::size_t max_size) {
  std::size_t len = 0;
  while (len < max_size && chars[len] != '\0') {
    len += 1;
  }
  return std::string(chars, len);
}

bool header_looks_valid(const IRSDKHeader *header, std::size_t size_bytes) {
  if (header == nullptr || size_bytes < sizeof(IRSDKHeader)) {
    return false;
  }
  if (header->version <= 0 || header->num_vars <= 0 || header->num_vars > 4096) {
    return false;
  }
  if (header->var_header_offset < 0 || header->buf_len <= 0) {
    return false;
  }

  const auto num_buf = clamp_num_buf(header->num_buf);
  if (num_buf == 0) {
    return false;
  }

  const auto vars_offset = static_cast<std::size_t>(header->var_header_offset);
  const auto vars_bytes = static_cast<std::size_t>(header->num_vars) * sizeof(IRSDKVarHeader);
  if (vars_offset + vars_bytes > size_bytes) {
    return false;
  }

  return true;
}

const IRSDKVarBuffer *latest_buffer(const IRSDKHeader *header, std::size_t size_bytes) {
  const auto num_buf = clamp_num_buf(header->num_buf);
  const auto buf_len = static_cast<std::size_t>(header->buf_len);

  const IRSDKVarBuffer *latest = nullptr;
  for (int32_t i = 0; i < num_buf; ++i) {
    const auto &candidate = header->var_buffers[i];
    if (candidate.buffer_offset < 0) {
      continue;
    }
    const auto offset = static_cast<std::size_t>(candidate.buffer_offset);
    if (offset + buf_len > size_bytes) {
      continue;
    }
    if (latest == nullptr || candidate.tick_count > latest->tick_count) {
      latest = &candidate;
    }
  }
  return latest;
}

void assign_field(const IRSDKVarHeader &header, FieldRef *field) {
  if (field == nullptr) {
    return;
  }
  field->type = header.type;
  field->offset = header.offset;
  field->count = header.count;
}

bool read_number_as_float(const uint8_t *frame, std::size_t frame_len,
                          const FieldRef &field, float *out_value) {
  if (!out_value || !field.is_valid()) {
    return false;
  }
  if (field.offset < 0) {
    return false;
  }

  const auto value_offset = static_cast<std::size_t>(field.offset);
  switch (static_cast<IRSDKVarType>(field.type)) {
  case IRSDKVarType::Float: {
    if (value_offset + sizeof(float) > frame_len) {
      return false;
    }
    float value = 0.0f;
    std::memcpy(&value, frame + value_offset, sizeof(value));
    *out_value = value;
    return true;
  }
  case IRSDKVarType::Double: {
    if (value_offset + sizeof(double) > frame_len) {
      return false;
    }
    double value = 0.0;
    std::memcpy(&value, frame + value_offset, sizeof(value));
    *out_value = static_cast<float>(value);
    return true;
  }
  case IRSDKVarType::Int:
  case IRSDKVarType::BitField:
  case IRSDKVarType::Bool: {
    if (value_offset + sizeof(int32_t) > frame_len) {
      return false;
    }
    int32_t value = 0;
    std::memcpy(&value, frame + value_offset, sizeof(value));
    *out_value = static_cast<float>(value);
    return true;
  }
  default:
    return false;
  }
}

class NativeIRacingSharedMemoryTransport final : public IIRacingSharedMemoryTransport {
public:
  ~NativeIRacingSharedMemoryTransport() override {
    close();
  }

  bool open() override {
    if (data_ != nullptr) {
      return true;
    }
#ifdef _WIN32
    map_ = OpenFileMappingW(FILE_MAP_READ, FALSE, kIRacingMemMapName);
    if (map_ == nullptr) {
      return false;
    }

    auto *view = MapViewOfFile(map_, FILE_MAP_READ, 0, 0, 0);
    if (view == nullptr) {
      close();
      return false;
    }

    MEMORY_BASIC_INFORMATION info{};
    if (VirtualQuery(view, &info, sizeof(info)) == 0) {
      UnmapViewOfFile(view);
      close();
      return false;
    }

    data_ = static_cast<const uint8_t *>(view);
    size_ = info.RegionSize;
    return true;
#else
    return false;
#endif
  }

  const uint8_t *data() const override {
    return data_;
  }

  std::size_t size() const override {
    return size_;
  }

private:
  void close() {
#ifdef _WIN32
    if (data_ != nullptr) {
      UnmapViewOfFile(data_);
      data_ = nullptr;
    }
    if (map_ != nullptr) {
      CloseHandle(map_);
      map_ = nullptr;
    }
#endif
    size_ = 0;
  }

  const uint8_t *data_ = nullptr;
  std::size_t size_ = 0;
#ifdef _WIN32
  HANDLE map_ = nullptr;
#endif
};

} // namespace

struct IRacingSharedMemoryAdapter::Impl {
  explicit Impl(std::unique_ptr<IIRacingSharedMemoryTransport> in_transport)
      : transport(std::move(in_transport)) {}

  bool ensure_started() {
    if (started) {
      return true;
    }
    if (!transport || !transport->open()) {
      return false;
    }
    started = true;
    fields_resolved = false;
    return true;
  }

  const IRSDKHeader *header() const {
    const auto *base = transport ? transport->data() : nullptr;
    const auto size_bytes = transport ? transport->size() : 0;
    if (base == nullptr || !header_looks_valid(reinterpret_cast<const IRSDKHeader *>(base), size_bytes)) {
      return nullptr;
    }
    return reinterpret_cast<const IRSDKHeader *>(base);
  }

  bool resolve_fields_if_needed() {
    if (fields_resolved) {
      return true;
    }

    const auto *base = transport ? transport->data() : nullptr;
    const auto size_bytes = transport ? transport->size() : 0;
    const auto *hdr = header();
    if (base == nullptr || hdr == nullptr) {
      return false;
    }

    speed = {};
    velocity_x = {};
    velocity_y = {};
    velocity_z = {};
    long_accel = {};
    lat_accel = {};
    vert_accel = {};
    yaw_rate = {};
    pitch_rate = {};
    roll_rate = {};

    const auto *vars = reinterpret_cast<const IRSDKVarHeader *>(base + hdr->var_header_offset);
    for (int32_t i = 0; i < hdr->num_vars; ++i) {
      const auto &var = vars[i];
      const auto name = c_str_copy(var.name, sizeof(var.name));
      if (name == "Speed") {
        assign_field(var, &speed);
      } else if (name == "VelocityX" || name == "VelX") {
        assign_field(var, &velocity_x);
      } else if (name == "VelocityY" || name == "VelY") {
        assign_field(var, &velocity_y);
      } else if (name == "VelocityZ" || name == "VelZ") {
        assign_field(var, &velocity_z);
      } else if (name == "LongAccel") {
        assign_field(var, &long_accel);
      } else if (name == "LatAccel") {
        assign_field(var, &lat_accel);
      } else if (name == "VertAccel") {
        assign_field(var, &vert_accel);
      } else if (name == "YawRate") {
        assign_field(var, &yaw_rate);
      } else if (name == "PitchRate") {
        assign_field(var, &pitch_rate);
      } else if (name == "RollRate") {
        assign_field(var, &roll_rate);
      }
    }

    fields_resolved = speed.is_valid() ||
      (velocity_x.is_valid() && velocity_y.is_valid() && velocity_z.is_valid());
    return fields_resolved;
  }

  bool is_connected() const {
    const auto *hdr = header();
    if (hdr == nullptr) {
      return false;
    }
    return (hdr->status & kIRSDKStatusConnected) != 0;
  }

  std::unique_ptr<IIRacingSharedMemoryTransport> transport;
  bool started = false;
  bool fields_resolved = false;
  int32_t last_tick = std::numeric_limits<int32_t>::min();

  FieldRef speed;
  FieldRef velocity_x;
  FieldRef velocity_y;
  FieldRef velocity_z;
  FieldRef long_accel;
  FieldRef lat_accel;
  FieldRef vert_accel;
  FieldRef yaw_rate;
  FieldRef pitch_rate;
  FieldRef roll_rate;
};

IRacingSharedMemoryAdapter::IRacingSharedMemoryAdapter()
    : IRacingSharedMemoryAdapter(std::make_unique<NativeIRacingSharedMemoryTransport>()) {}

IRacingSharedMemoryAdapter::IRacingSharedMemoryAdapter(
    std::unique_ptr<IIRacingSharedMemoryTransport> transport)
    : impl_(std::make_unique<Impl>(std::move(transport))) {}

IRacingSharedMemoryAdapter::~IRacingSharedMemoryAdapter() = default;

GameId IRacingSharedMemoryAdapter::game_id() const {
  return GameId::IRacing;
}

bool IRacingSharedMemoryAdapter::probe(std::chrono::milliseconds) {
  if (!start()) {
    return false;
  }
  return impl_->is_connected() && impl_->resolve_fields_if_needed();
}

bool IRacingSharedMemoryAdapter::start() {
  if (!impl_->ensure_started()) {
    return false;
  }
  return impl_->resolve_fields_if_needed();
}

bool IRacingSharedMemoryAdapter::read(TelemetrySample &out_sample) {
  if (!start() || !impl_->is_connected()) {
    return false;
  }

  const auto *base = impl_->transport->data();
  const auto size_bytes = impl_->transport->size();
  const auto *hdr = impl_->header();
  if (base == nullptr || hdr == nullptr) {
    return false;
  }

  const auto *buffer = latest_buffer(hdr, size_bytes);
  if (buffer == nullptr) {
    return false;
  }
  if (buffer->tick_count == impl_->last_tick) {
    return false;
  }

  const auto frame_offset = static_cast<std::size_t>(buffer->buffer_offset);
  const auto frame_len = static_cast<std::size_t>(hdr->buf_len);
  if (frame_offset + frame_len > size_bytes) {
    return false;
  }
  const auto *frame = base + frame_offset;

  float speed_mps = 0.0f;
  const bool has_speed = read_number_as_float(frame, frame_len, impl_->speed, &speed_mps);

  float raw_velocity[3] = {0.0f, 0.0f, 0.0f};
  const bool has_vx = read_number_as_float(frame, frame_len, impl_->velocity_x, &raw_velocity[0]);
  const bool has_vy = read_number_as_float(frame, frame_len, impl_->velocity_y, &raw_velocity[1]);
  const bool has_vz = read_number_as_float(frame, frame_len, impl_->velocity_z, &raw_velocity[2]);
  const bool has_velocity = has_vx && has_vy && has_vz;

  out_sample.timestamp_ns = now_ns();
  out_sample.accel_mps2[0] = 0.0f;
  out_sample.accel_mps2[1] = 0.0f;
  out_sample.accel_mps2[2] = 0.0f;
  out_sample.velocity_mps[0] = 0.0f;
  out_sample.velocity_mps[1] = 0.0f;
  out_sample.velocity_mps[2] = 0.0f;
  out_sample.angular_vel_rad[0] = 0.0f;
  out_sample.angular_vel_rad[1] = 0.0f;
  out_sample.angular_vel_rad[2] = 0.0f;

  if (has_velocity) {
    normalize_vector_to_z_up(raw_velocity, UpAxis::YUp, out_sample.velocity_mps);
  } else if (has_speed) {
    out_sample.velocity_mps[0] = speed_mps;
  }

  read_number_as_float(frame, frame_len, impl_->long_accel, &out_sample.accel_mps2[0]);
  read_number_as_float(frame, frame_len, impl_->lat_accel, &out_sample.accel_mps2[1]);
  read_number_as_float(frame, frame_len, impl_->vert_accel, &out_sample.accel_mps2[2]);

  read_number_as_float(frame, frame_len, impl_->roll_rate, &out_sample.angular_vel_rad[0]);
  read_number_as_float(frame, frame_len, impl_->pitch_rate, &out_sample.angular_vel_rad[1]);
  read_number_as_float(frame, frame_len, impl_->yaw_rate, &out_sample.angular_vel_rad[2]);

  if (has_speed) {
    out_sample.speed_mps = speed_mps;
  } else {
    const auto vx = out_sample.velocity_mps[0];
    const auto vy = out_sample.velocity_mps[1];
    const auto vz = out_sample.velocity_mps[2];
    out_sample.speed_mps = std::sqrt((vx * vx) + (vy * vy) + (vz * vz));
  }

  impl_->last_tick = buffer->tick_count;
  return has_speed || has_velocity;
}

std::unique_ptr<IGameTelemetryAdapter> make_iracing_shared_memory_adapter_for_testing(
    std::unique_ptr<IIRacingSharedMemoryTransport> transport) {
  return std::make_unique<IRacingSharedMemoryAdapter>(std::move(transport));
}

} // namespace slipstream::physics

void slipstream_register_game_adapters(slipstream::physics::GameAdapterRegistry *registry) {
  if (registry == nullptr) {
    return;
  }
  registry->register_adapter(
      slipstream::physics::GameId::IRacing,
      []() { return std::make_unique<slipstream::physics::IRacingSharedMemoryAdapter>(); });
}

