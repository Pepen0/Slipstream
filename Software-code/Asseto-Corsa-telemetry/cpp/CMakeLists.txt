cmake_minimum_required(VERSION 3.24)
project(SlipstreamTelemetryBridge LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_definitions(-D_WIN32_WINNT=0x0A00) # Windows 10

# gRPC + Protobuf
find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)

set(PROTO_FILE ${CMAKE_SOURCE_DIR}/../proto/telemetry/v1/telemetry.proto)

# Generate sources
set(GENERATED_DIR ${CMAKE_BINARY_DIR}/generated)
file(MAKE_DIRECTORY ${GENERATED_DIR})

protobuf_generate(TARGET telemetry_proto
  LANGUAGE cpp
  PROTOS ${PROTO_FILE}
  PROTOC_OUT_DIR ${GENERATED_DIR})

# gRPC codegen
get_filename_component(PROTO_ABS ${PROTO_FILE} ABSOLUTE)
set(PROTO_IMPORT_DIRS ${CMAKE_SOURCE_DIR}/../proto)
set(GRPC_SRCS ${GENERATED_DIR}/telemetry/v1/telemetry.grpc.pb.cc)
set(GRPC_HDRS ${GENERATED_DIR}/telemetry/v1/telemetry.grpc.pb.h)
set(PB_SRCS   ${GENERATED_DIR}/telemetry/v1/telemetry.pb.cc)
set(PB_HDRS   ${GENERATED_DIR}/telemetry/v1/telemetry.pb.h)

add_custom_command(
  OUTPUT ${GRPC_SRCS} ${GRPC_HDRS} ${PB_SRCS} ${PB_HDRS}
  COMMAND $<TARGET_FILE:protobuf::protoc>
  ARGS --grpc_out ${GENERATED_DIR}
       --cpp_out ${GENERATED_DIR}
       --plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>
       -I ${PROTO_IMPORT_DIRS}
       ${PROTO_ABS}
  DEPENDS ${PROTO_ABS} protobuf::protoc gRPC::grpc_cpp_plugin)

add_library(telemetry_proto STATIC ${GRPC_SRCS} ${PB_SRCS})
target_include_directories(telemetry_proto PUBLIC ${GENERATED_DIR})
target_link_libraries(telemetry_proto PUBLIC protobuf::libprotobuf gRPC::grpc++)

add_executable(telemetry_bridge
  src/main.cpp
  src/ac_shmem.hpp
  src/recorder.hpp
  src/recorder.cpp)

target_include_directories(telemetry_bridge PRIVATE ${GENERATED_DIR})
target_link_libraries(telemetry_bridge PRIVATE telemetry_proto protobuf::libprotobuf gRPC::grpc++)
target_compile_definitions(telemetry_bridge PRIVATE UNICODE _UNICODE NOMINMAX)
