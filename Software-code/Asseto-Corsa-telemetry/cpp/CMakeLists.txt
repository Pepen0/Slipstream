cmake_minimum_required(VERSION 3.24)
project(SlipstreamTelemetryBridge LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_definitions(-D_WIN32_WINNT=0x0A00)

find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)
find_package(ZLIB REQUIRED)

set(PROTO_DIR  ${CMAKE_CURRENT_SOURCE_DIR}/../proto/telemetry/v1)
set(PROTO_FILE ${PROTO_DIR}/telemetry.proto)
set(GEN_DIR    ${CMAKE_CURRENT_BINARY_DIR}/_generated)

file(MAKE_DIRECTORY ${GEN_DIR})

# Paths to tools
set(PROTOC               $<TARGET_FILE:protobuf::protoc>)
set(GRPC_CPP_PLUGIN      $<TARGET_FILE:gRPC::grpc_cpp_plugin>)

# Generated sources
set(GEN_PROTO_SRCS ${GEN_DIR}/telemetry.pb.cc)
set(GEN_PROTO_HDRS ${GEN_DIR}/telemetry.pb.h)
set(GEN_GRPC_SRCS  ${GEN_DIR}/telemetry.grpc.pb.cc)
set(GEN_GRPC_HDRS  ${GEN_DIR}/telemetry.grpc.pb.h)

add_custom_command(
  OUTPUT ${GEN_PROTO_SRCS} ${GEN_PROTO_HDRS}
  COMMAND ${PROTOC}
    --cpp_out=${GEN_DIR}
    -I ${CMAKE_CURRENT_SOURCE_DIR}/../proto
    ${PROTO_FILE}
  DEPENDS ${PROTO_FILE}
  COMMENT "Generating C++ protobuf sources"
  VERBATIM)

add_custom_command(
  OUTPUT ${GEN_GRPC_SRCS} ${GEN_GRPC_HDRS}
  COMMAND ${PROTOC}
    --grpc_out=${GEN_DIR}
    --plugin=protoc-gen-grpc=${GRPC_CPP_PLUGIN}
    -I ${CMAKE_CURRENT_SOURCE_DIR}/../proto
    ${PROTO_FILE}
  DEPENDS ${PROTO_FILE}
  COMMENT "Generating C++ gRPC sources"
  VERBATIM)

add_library(telemetry_proto
  ${GEN_PROTO_SRCS} ${GEN_PROTO_HDRS}
  ${GEN_GRPC_SRCS}  ${GEN_GRPC_HDRS}
)
target_include_directories(telemetry_proto PUBLIC ${GEN_DIR})
target_link_libraries(telemetry_proto PUBLIC protobuf::libprotobuf gRPC::grpc++)

add_executable(telemetry_bridge
  src/main.cpp
  src/recorder.cpp
  src/recorder.hpp
  src/ac_shmem.hpp
)
target_link_libraries(telemetry_bridge
  PRIVATE
    telemetry_proto
    gRPC::grpc++
    protobuf::libprotobuf
    ZLIB::ZLIB
)
target_compile_definitions(telemetry_bridge PRIVATE UNICODE _UNICODE NOMINMAX)
set_target_properties(telemetry_bridge PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
