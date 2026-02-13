#include "iracing_adapter_plugin.h"

#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

using slipstream::physics::GameAdapterRegistry;
using slipstream::physics::GameId;
using slipstream::physics::IIRacingSharedMemoryTransport;
using slipstream::physics::IGameTelemetryAdapter;
using slipstream::physics::TelemetrySample;
using slipstream::physics::make_iracing_shared_memory_adapter_for_testing;

namespace {

constexpr int32_t kIRSDKStatusConnected = 0x1;
constexpr int32_t kIRSDKMaxBuf = 4;
constexpr int32_t kIRSDKMaxString = 32;
constexpr int32_t kIRSDKDescLen = 64;
constexpr int32_t kTypeFloat = 4;

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

struct FakeIRacingImage {
  std::vector<uint8_t> bytes;
  std::size_t latest_buffer_offset = 0;
  std::size_t speed_value_offset = 0;
};

class FakeTransport final : public IIRacingSharedMemoryTransport {
public:
  explicit FakeTransport(FakeIRacingImage image) : image_(std::move(image)) {}

  bool open() override {
    opened_ = true;
    return true;
  }

  const uint8_t *data() const override {
    if (!opened_) {
      return nullptr;
    }
    return image_.bytes.data();
  }

  std::size_t size() const override {
    if (!opened_) {
      return 0;
    }
    return image_.bytes.size();
  }

  void bump_tick() {
    auto *header = reinterpret_cast<IRSDKHeader *>(image_.bytes.data());
    header->var_buffers[1].tick_count += 1;
  }

  void set_speed(float speed_mps) {
    std::memcpy(image_.bytes.data() + image_.latest_buffer_offset + image_.speed_value_offset,
                &speed_mps, sizeof(speed_mps));
  }

private:
  FakeIRacingImage image_;
  bool opened_ = false;
};

bool nearly_equal(float lhs, float rhs, float eps = 1e-4f) {
  return std::fabs(lhs - rhs) <= eps;
}

void write_name(char out[kIRSDKMaxString], const char *value) {
  std::memset(out, 0, kIRSDKMaxString);
  std::strncpy(out, value, kIRSDKMaxString - 1);
}

void write_float(std::vector<uint8_t> &bytes, std::size_t absolute_offset, float value) {
  std::memcpy(bytes.data() + absolute_offset, &value, sizeof(value));
}

FakeIRacingImage build_fake_image() {
  struct Field {
    const char *name;
    float value;
  };

  const std::vector<Field> fields = {
    {"Speed", 55.0f},     {"VelocityX", 10.0f}, {"VelocityY", 2.0f},
    {"VelocityZ", 30.0f}, {"LongAccel", 1.25f}, {"LatAccel", -0.5f},
    {"VertAccel", 0.2f},  {"RollRate", 0.1f},   {"PitchRate", 0.2f},
    {"YawRate", 0.3f},
  };

  const auto header_size = sizeof(IRSDKHeader);
  const auto var_header_offset = header_size;
  const auto var_headers_size = fields.size() * sizeof(IRSDKVarHeader);
  const auto buffer_len = static_cast<std::size_t>(256);
  const auto buf0_offset = var_header_offset + var_headers_size;
  const auto buf1_offset = buf0_offset + buffer_len;
  const auto total_size = buf1_offset + buffer_len;

  FakeIRacingImage image;
  image.bytes.assign(total_size, 0);
  image.latest_buffer_offset = buf1_offset;

  auto *header = reinterpret_cast<IRSDKHeader *>(image.bytes.data());
  header->version = 1;
  header->status = kIRSDKStatusConnected;
  header->tick_rate = 60;
  header->num_vars = static_cast<int32_t>(fields.size());
  header->var_header_offset = static_cast<int32_t>(var_header_offset);
  header->num_buf = 2;
  header->buf_len = static_cast<int32_t>(buffer_len);
  header->var_buffers[0].tick_count = 10;
  header->var_buffers[0].buffer_offset = static_cast<int32_t>(buf0_offset);
  header->var_buffers[1].tick_count = 11;
  header->var_buffers[1].buffer_offset = static_cast<int32_t>(buf1_offset);

  auto *var_headers = reinterpret_cast<IRSDKVarHeader *>(image.bytes.data() + var_header_offset);
  std::size_t field_offset = 0;
  for (std::size_t i = 0; i < fields.size(); ++i) {
    auto &var = var_headers[i];
    var.type = kTypeFloat;
    var.offset = static_cast<int32_t>(field_offset);
    var.count = 1;
    var.count_as_time = 0;
    write_name(var.name, fields[i].name);

    const auto abs0 = buf0_offset + field_offset;
    const auto abs1 = buf1_offset + field_offset;
    write_float(image.bytes, abs0, fields[i].value * 0.5f);
    write_float(image.bytes, abs1, fields[i].value);

    if (std::string(fields[i].name) == "Speed") {
      image.speed_value_offset = field_offset;
    }

    field_offset += sizeof(float);
  }

  return image;
}

class DummyAdapter final : public IGameTelemetryAdapter {
public:
  GameId game_id() const override {
    return GameId::AssettoCorsa;
  }

  bool probe(std::chrono::milliseconds) override {
    return false;
  }

  bool start() override {
    return false;
  }

  bool read(TelemetrySample &) override {
    return false;
  }
};

} // namespace

int main() {
  {
    auto transport = std::make_unique<FakeTransport>(build_fake_image());
    auto *transport_ptr = transport.get();

    auto adapter = make_iracing_shared_memory_adapter_for_testing(std::move(transport));
    assert(adapter != nullptr);
    assert(adapter->game_id() == GameId::IRacing);
    assert(adapter->start());
    assert(adapter->probe(std::chrono::milliseconds(1)));

    TelemetrySample sample{};
    assert(adapter->read(sample));
    assert(nearly_equal(sample.speed_mps, 55.0f));
    assert(nearly_equal(sample.velocity_mps[0], 10.0f));
    assert(nearly_equal(sample.velocity_mps[1], 30.0f));
    assert(nearly_equal(sample.velocity_mps[2], 2.0f));
    assert(nearly_equal(sample.accel_mps2[0], 1.25f));
    assert(nearly_equal(sample.accel_mps2[1], -0.5f));
    assert(nearly_equal(sample.accel_mps2[2], 0.2f));
    assert(nearly_equal(sample.angular_vel_rad[0], 0.1f));
    assert(nearly_equal(sample.angular_vel_rad[1], 0.2f));
    assert(nearly_equal(sample.angular_vel_rad[2], 0.3f));

    assert(!adapter->read(sample));

    transport_ptr->bump_tick();
    transport_ptr->set_speed(61.0f);
    assert(adapter->read(sample));
    assert(nearly_equal(sample.speed_mps, 61.0f));
  }

  {
    GameAdapterRegistry registry;
    registry.register_adapter(GameId::IRacing, []() { return std::make_unique<DummyAdapter>(); });
    auto before = registry.create(GameId::IRacing);
    assert(before != nullptr);
    assert(before->game_id() == GameId::AssettoCorsa);

    slipstream_register_game_adapters(&registry);
    auto after = registry.create(GameId::IRacing);
    assert(after != nullptr);
    assert(after->game_id() == GameId::IRacing);
  }

  return 0;
}

