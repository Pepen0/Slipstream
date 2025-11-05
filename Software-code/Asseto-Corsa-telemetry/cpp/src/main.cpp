#include <windows.h>
#include <Rpc.h> // UuidCreate
#include <chrono>
#include <iostream>
#include <string>
#include <thread>
#include <atomic>
#include <memory>

#include "ac_shmem.hpp"
#include "recorder.hpp"

#include "telemetry/v1/telemetry.pb.h"
#include "telemetry/v1/telemetry.grpc.pb.h"

#include <grpcpp/grpcpp.h>

using telemetry::v1::TelemetryIngest;
using telemetry::v1::TelemetryFrame;
using telemetry::v1::Physics;
using telemetry::v1::Graphics;
using telemetry::v1::Static;
using telemetry::v1::StreamAck;

static std::string make_uuid() {
  UUID uuid; UuidCreate(&uuid);
  RPC_CSTR str; UuidToStringA(&uuid, &str);
  std::string out(reinterpret_cast<char*>(str));
  RpcStringFreeA(&str);
  return out;
}

struct ShmHandle {
  HANDLE h_map{};
  void*  view{};
  size_t size{};
  ~ShmHandle() {
    if (view) UnmapViewOfFile(view);
    if (h_map) CloseHandle(h_map);
  }
};

static ShmHandle open_shm(const wchar_t* name, size_t size) {
  ShmHandle h{};
  h.h_map = OpenFileMappingW(FILE_MAP_READ, FALSE, name);
  if (!h.h_map) throw std::runtime_error("OpenFileMappingW failed");
  h.view = MapViewOfFile(h.h_map, FILE_MAP_READ, 0, 0, size);
  if (!h.view) throw std::runtime_error("MapViewOfFile failed");
  h.size = size;
  return h;
}

static uint64_t now_ns() {
  using clock = std::chrono::steady_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(clock::now().time_since_epoch()).count();
}

int wmain(int argc, wchar_t** argv) {
  const char* target = (argc >= 2) ? std::string().assign(
      std::wstring_convert<std::codecvt_utf8<wchar_t>>().to_bytes(argv[1])).c_str()
    : "127.0.0.1:50051";

  std::string session_id = make_uuid();

  // Open AC shared memories
  auto shm_phys = open_shm(AC_SHM_PHYSICS,  sizeof(SPageFilePhysics));
  auto shm_gfx  = open_shm(AC_SHM_GRAPHICS, sizeof(SPageFileGraphics));
  auto shm_stat = open_shm(AC_SHM_STATIC,   sizeof(SPageFileStatic));

  // gRPC channel
  auto channel = grpc::CreateChannel(target, grpc::InsecureChannelCredentials());
  auto stub    = TelemetryIngest::NewStub(channel);
  grpc::ClientContext ctx;
  std::unique_ptr<grpc::ClientReaderWriter<TelemetryFrame, StreamAck>> stream(
      stub->StreamFrames(&ctx));

  // Recorder
  FrameRecorder recorder(L"telemetry_record.pb.gz");

  std::atomic<bool> running{true};
  std::thread ack_thread([&]{
    StreamAck ack;
    while (stream->Read(&ack)) {
      // Optional: backpressure / rate adjust based on ack
      (void)ack;
    }
    running = false;
  });

  // 333 Hz loop
  const auto period = std::chrono::microseconds(3000);
  auto next_tick = std::chrono::steady_clock::now();

  while (running.load()) {
    next_tick += period;

    auto* p = reinterpret_cast<const SPageFilePhysics*>(shm_phys.view);
    auto* g = reinterpret_cast<const SPageFileGraphics*>(shm_gfx.view);
    auto* s = reinterpret_cast<const SPageFileStatic*>(shm_stat.view);

    TelemetryFrame frame;
    frame.set_monotonic_ns(now_ns());
    frame.set_game("assetto_corsa");
    frame.set_session_id(session_id);

    Physics* pp = frame.mutable_physics();
    pp->set_speed_kmh(p->speedKmh);
    pp->set_gas(p->gas);
    pp->set_brake(p->brake);
    pp->set_clutch(0.0f); // AC physics page doesn't expose clutch position in all versions
    pp->set_gear(p->gear);
    pp->set_steer(p->steerAngle / 180.0f); // normalize roughly
    pp->set_engine_rpm(static_cast<float>(p->rpms));

    auto* slip = pp->mutable_tyre_slip();
    slip->set_fl(p->tyreSlip[0]); slip->set_fr(p->tyreSlip[1]);
    slip->set_rl(p->tyreSlip[2]); slip->set_rr(p->tyreSlip[3]);

    auto* load = pp->mutable_tyre_load();
    load->set_fl(p->tyreLoad[0]); load->set_fr(p->tyreLoad[1]);
    load->set_rl(p->tyreLoad[2]); load->set_rr(p->tyreLoad[3]);

    auto* temp = pp->mutable_tyre_temp_c();
    temp->set_fl(p->tyreCoreTemp[0]); temp->set_fr(p->tyreCoreTemp[1]);
    temp->set_rl(p->tyreCoreTemp[2]); temp->set_rr(p->tyreCoreTemp[3]);

    auto* sus = pp->mutable_suspension_travel();
    sus->set_fl(p->suspensionTravel[0]); sus->set_fr(p->suspensionTravel[1]);
    sus->set_rl(p->suspensionTravel[2]); sus->set_rr(p->suspensionTravel[3]);

    auto* acc = pp->mutable_acc_g();
    acc->set_x(p->accG[0]); acc->set_y(p->accG[1]); acc->set_z(p->accG[2]);

    auto* vel = pp->mutable_velocity();
    vel->set_x(p->velocity[0]); vel->set_y(p->velocity[1]); vel->set_z(p->velocity[2]);

    auto* ang = pp->mutable_angular_velocity();
    ang->set_x(p->angularVelocity[0]); ang->set_y(p->angularVelocity[1]); ang->set_z(p->angularVelocity[2]);

    Graphics* gg = frame.mutable_graphics();
    gg->set_status(g->status);
    gg->set_completed_laps(g->completedLaps);
    gg->set_position(g->position);
    gg->set_i_current_time_s(g->iCurrentTime);
    gg->set_i_last_time_s(g->iLastTime);
    gg->set_i_best_time_s(g->iBestTime);
    gg->set_lap_time_s(g->lapTime);
    gg->set_delta_lap_s(g->deltaLapTime);
    gg->set_normalized_car_pos(g->normalizedCarPosition);

    Static* ss = frame.mutable_stat();
    ss->set_car_model(std::string(s->carModel));
    ss->set_track(std::string(s->track));
    ss->set_track_configuration(std::string(s->trackConfiguration));
    ss->set_max_rpm(s->maxRpm);

    // Send to server
    if (!stream->Write(frame)) {
      std::cerr << "gRPC write failed; stopping stream\n";
      running = false;
      break;
    }

    // Record locally (length-delimited TelemetryFrame)
    std::string payload;
    frame.SerializeToString(&payload);
    recorder.write(payload.data(), payload.size());

    std::this_thread::sleep_until(next_tick);
  }

  stream->WritesDone();
  grpc::Status st = stream->Finish();
  if (!st.ok()) {
    std::cerr << "Stream finished with error: " << st.error_message() << "\n";
  }
  if (ack_thread.joinable()) ack_thread.join();
  return 0;
}
