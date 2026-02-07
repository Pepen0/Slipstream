#include "assetto_corsa_adapter.h"

#include "ac_shmem.hpp"
#include "coordinate_normalizer.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <chrono>
#include <stdexcept>

namespace slipstream::physics {

struct ShmHandle {
  HANDLE map = nullptr;
  void *view = nullptr;
  size_t size = 0;
  ~ShmHandle() {
    if (view) {
      UnmapViewOfFile(view);
    }
    if (map) {
      CloseHandle(map);
    }
  }
};

static uint64_t now_ns() {
  using clock = std::chrono::steady_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(clock::now().time_since_epoch()).count();
}

struct AssettoCorsaAdapter::Impl {
  ShmHandle phys;
  ShmHandle gfx;
  ShmHandle stat;
  int32_t last_packet = -1;
};

AssettoCorsaAdapter::AssettoCorsaAdapter() : impl_(new Impl()) {}
AssettoCorsaAdapter::~AssettoCorsaAdapter() {
  delete impl_;
}

GameId AssettoCorsaAdapter::game_id() const {
  return GameId::AssettoCorsa;
}

bool AssettoCorsaAdapter::probe(std::chrono::milliseconds) {
  return start();
}

static ShmHandle open_shm(const wchar_t *name, size_t size) {
  ShmHandle h;
  h.map = OpenFileMappingW(FILE_MAP_READ, FALSE, name);
  if (!h.map) {
    throw std::runtime_error("OpenFileMappingW failed");
  }
  h.view = MapViewOfFile(h.map, FILE_MAP_READ, 0, 0, size);
  if (!h.view) {
    throw std::runtime_error("MapViewOfFile failed");
  }
  h.size = size;
  return h;
}

bool AssettoCorsaAdapter::start() {
  if (impl_->phys.view && impl_->gfx.view && impl_->stat.view) {
    return true;
  }

  try {
    impl_->phys = open_shm(AC_SHM_PHYSICS, sizeof(SPageFilePhysics));
    impl_->gfx = open_shm(AC_SHM_GRAPHICS, sizeof(SPageFileGraphics));
    impl_->stat = open_shm(AC_SHM_STATIC, sizeof(SPageFileStatic));
  } catch (...) {
    return false;
  }
  return true;
}

bool AssettoCorsaAdapter::read(TelemetrySample &out_sample) {
  if (!impl_->phys.view) {
    return false;
  }

  auto *p = reinterpret_cast<const SPageFilePhysics *>(impl_->phys.view);
  if (p->packetId == impl_->last_packet) {
    return false;
  }
  impl_->last_packet = p->packetId;

  out_sample.timestamp_ns = now_ns();
  constexpr float g = 9.80665f;
  float accel_raw[3] = {p->accG[0] * g, p->accG[1] * g, p->accG[2] * g};
  float velocity_raw[3] = {p->velocity[0], p->velocity[1], p->velocity[2]};
  float angular_raw[3] = {p->angularVelocity[0], p->angularVelocity[1], p->angularVelocity[2]};

  normalize_vector_to_z_up(accel_raw, UpAxis::ZUp, out_sample.accel_mps2);
  normalize_vector_to_z_up(velocity_raw, UpAxis::ZUp, out_sample.velocity_mps);
  normalize_vector_to_z_up(angular_raw, UpAxis::ZUp, out_sample.angular_vel_rad);

  out_sample.speed_mps = p->speedKmh / 3.6f;
  return true;
}

} // namespace slipstream::physics
