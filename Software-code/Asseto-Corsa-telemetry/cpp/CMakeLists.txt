cmake_minimum_required(VERSION 3.24)
project(SlipstreamTelemetryBridge LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_definitions(-D_WIN32_WINNT=0x0A00) # Windows 10

# Dependencies from vcpkg
find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)
find_package(ZLIB REQUIRED)

# --- Proto paths
set(PROTO_DIR  ${CMAKE_CURRENT_SOURCE_DIR}/../proto)
set(PROTO_FILE ${PROTO_DIR}/telemetry/v1/telemetry.proto)

# --- Generated code target (protobuf + gRPC)
add_library(telemetry_proto)

# Make generated headers visible to dependents
target_include_directories(telemetry_proto PUBLIC ${CMAKE_CURRENT_BINARY_DIR})

# Link core libs for anyone using the proto target
target_link_libraries(telemetry_proto
  PUBLIC
    protobuf::libprotobuf
    gRPC::grpc++
)

# Generate C++ protobuf and gRPC sources into the build tree
# (macros provided by vcpkg's protobuf/grpc packages)
protobuf_generate(
  TARGET telemetry_proto
  PROTOS ${PROTO_FILE}
)

grpc_generate(
  TARGET telemetry_proto
  PROTOS ${PROTO_FILE}
)

# --- Bridge executable
add_executable(telemetry_bridge
  src/main.cpp
  src/recorder.cpp
  src/recorder.hpp
  src/ac_shmem.hpp
)

target_link_libraries(telemetry_bridge
  PRIVATE
    telemetry_proto
    protobuf::libprotobuf
    gRPC::grpc++
    ZLIB::ZLIB
)

target_compile_definitions(telemetry_bridge PRIVATE UNICODE _UNICODE NOMINMAX)

# Optional: put the exe next to the build dir root (helps with manual running)
set_target_properties(telemetry_bridge PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
