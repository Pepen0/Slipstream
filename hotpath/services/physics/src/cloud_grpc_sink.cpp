#ifdef SLIPSTREAM_ENABLE_GRPC

#include "cloud_grpc_sink.h"

#include "telemetry/v1/telemetry.pb.h"
#include "telemetry/v1/telemetry.grpc.pb.h"

#include <grpcpp/grpcpp.h>

#include <atomic>
#include <chrono>
#include <memory>
#include <thread>

namespace slipstream::physics {

using telemetry::v1::TelemetryFrame;
using telemetry::v1::TelemetryIngest;
using telemetry::v1::StreamAck;

struct GrpcTelemetrySink::Impl {
  std::shared_ptr<grpc::Channel> channel;
  std::unique_ptr<TelemetryIngest::Stub> stub;
  std::unique_ptr<grpc::ClientContext> context;
  std::unique_ptr<grpc::ClientReaderWriter<TelemetryFrame, StreamAck>> stream;
  std::thread ack_thread;
  std::atomic<bool> running{false};
};

static float to_g(float accel_mps2) {
  constexpr float kG = 9.80665f;
  return accel_mps2 / kG;
}

GrpcTelemetrySink::GrpcTelemetrySink(GrpcTelemetryConfig config)
    : config_(std::move(config)), impl_(new Impl()) {}

GrpcTelemetrySink::~GrpcTelemetrySink() {
  reset_stream();
  delete impl_;
}

void GrpcTelemetrySink::ensure_stream() {
  if (impl_->stream) {
    return;
  }
  impl_->channel = grpc::CreateChannel(config_.target, grpc::InsecureChannelCredentials());
  impl_->stub = TelemetryIngest::NewStub(impl_->channel);
  impl_->context = std::make_unique<grpc::ClientContext>();
  impl_->stream = impl_->stub->StreamFrames(impl_->context.get());
  impl_->running = true;
  impl_->ack_thread = std::thread([this] {
    StreamAck ack;
    while (impl_->stream && impl_->stream->Read(&ack)) {
      (void)ack;
    }
  });
}

void GrpcTelemetrySink::reset_stream() {
  if (!impl_) return;
  impl_->running = false;
  if (impl_->stream) {
    impl_->stream->WritesDone();
    impl_->stream->Finish();
    impl_->stream.reset();
  }
  if (impl_->ack_thread.joinable()) {
    impl_->ack_thread.join();
  }
  impl_->context.reset();
  impl_->stub.reset();
  impl_->channel.reset();
}

bool GrpcTelemetrySink::send(const CloudTelemetryFrame &frame) {
  ensure_stream();
  if (!impl_->stream) {
    return false;
  }
  TelemetryFrame out;
  out.set_monotonic_ns(frame.monotonic_ns);
  out.set_game(config_.game);
  out.set_session_id(config_.session_id);

  auto *phys = out.mutable_physics();
  phys->set_speed_kmh(frame.sample.speed_mps * 3.6f);
  phys->set_engine_rpm(0.0f);
  phys->set_gear(0);
  phys->set_gas(0.0f);
  phys->set_brake(0.0f);
  phys->set_clutch(0.0f);
  phys->set_steer(0.0f);

  auto *acc = phys->mutable_acc_g();
  acc->set_x(to_g(frame.sample.accel_mps2[0]));
  acc->set_y(to_g(frame.sample.accel_mps2[1]));
  acc->set_z(to_g(frame.sample.accel_mps2[2]));

  auto *vel = phys->mutable_velocity();
  vel->set_x(frame.sample.velocity_mps[0]);
  vel->set_y(frame.sample.velocity_mps[1]);
  vel->set_z(frame.sample.velocity_mps[2]);

  auto *ang = phys->mutable_angular_velocity();
  ang->set_x(frame.sample.angular_vel_rad[0]);
  ang->set_y(frame.sample.angular_vel_rad[1]);
  ang->set_z(frame.sample.angular_vel_rad[2]);

  if (!impl_->stream->Write(out)) {
    reset_stream();
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    return false;
  }
  return true;
}

} // namespace slipstream::physics

#endif
