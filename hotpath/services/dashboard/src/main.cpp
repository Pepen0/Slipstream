#include "dashboard_state.h"
#include "logger.h"

#include "dashboard/v1/dashboard.grpc.pb.h"

#include <grpcpp/grpcpp.h>

#include <iostream>
#include <memory>
#include <string>

namespace slipstream::dashboard {
DashboardService::Service *make_dashboard_service();
}

int main(int argc, char **argv) {
  std::string address = "127.0.0.1:50060";
  if (argc > 1) {
    address = argv[1];
  }

  std::unique_ptr<dashboard::v1::DashboardService::Service> service(
      slipstream::dashboard::make_dashboard_service());

  grpc::ServerBuilder builder;
  builder.AddListeningPort(address, grpc::InsecureServerCredentials());
  builder.RegisterService(service.get());

  std::unique_ptr<grpc::Server> server(builder.BuildAndStart());
  slipstream::dashboard::log_info("Dashboard server listening on " + address);
  server->Wait();
  return 0;
}
