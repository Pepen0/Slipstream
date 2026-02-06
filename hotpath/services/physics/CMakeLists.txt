cmake_minimum_required(VERSION 3.20)
project(slipstream_physics LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(physics_core)
target_include_directories(physics_core PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR}/../../src/games/Asseto-Corsa
)

target_sources(physics_core PRIVATE
  src/filters.cpp
  src/transform.cpp
  src/kinematics.cpp
  src/motion_engine.cpp
  src/motion_loop.cpp
  src/cloud_streamer.cpp
)

if (WIN32)
  target_sources(physics_core PRIVATE src/assetto_corsa_adapter_win.cpp)
  target_compile_definitions(physics_core PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
else()
  target_sources(physics_core PRIVATE src/assetto_corsa_adapter_stub.cpp)
endif()

find_package(Protobuf CONFIG QUIET)
find_package(gRPC CONFIG QUIET)
if (Protobuf_FOUND AND gRPC_FOUND)
  set(PROTO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../shared/protos")
  set(PROTO_FILE "${PROTO_ROOT}/telemetry/v1/telemetry.proto")
  if (EXISTS "${PROTO_FILE}")
    set(GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/_generated)
    set(GEN_SUBDIR ${GEN_DIR}/telemetry/v1)
    file(MAKE_DIRECTORY ${GEN_SUBDIR})

    set(PROTOC          $<TARGET_FILE:protobuf::protoc>)
    set(GRPC_CPP_PLUGIN $<TARGET_FILE:gRPC::grpc_cpp_plugin>)

    set(GEN_PROTO_SRCS ${GEN_SUBDIR}/telemetry.pb.cc)
    set(GEN_PROTO_HDRS ${GEN_SUBDIR}/telemetry.pb.h)
    set(GEN_GRPC_SRCS  ${GEN_SUBDIR}/telemetry.grpc.pb.cc)
    set(GEN_GRPC_HDRS  ${GEN_SUBDIR}/telemetry.grpc.pb.h)

    add_custom_command(
      OUTPUT ${GEN_PROTO_SRCS} ${GEN_PROTO_HDRS}
      COMMAND ${PROTOC}
        --cpp_out=${GEN_DIR}
        -I ${PROTO_ROOT}
        ${PROTO_FILE}
      DEPENDS ${PROTO_FILE}
      COMMENT "Generating telemetry protobuf sources"
      VERBATIM
    )

    add_custom_command(
      OUTPUT ${GEN_GRPC_SRCS} ${GEN_GRPC_HDRS}
      COMMAND ${PROTOC}
        --grpc_out=${GEN_DIR}
        --plugin=protoc-gen-grpc=${GRPC_CPP_PLUGIN}
        -I ${PROTO_ROOT}
        ${PROTO_FILE}
      DEPENDS ${PROTO_FILE}
      COMMENT "Generating telemetry gRPC sources"
      VERBATIM
    )

    add_library(telemetry_proto
      ${GEN_PROTO_SRCS} ${GEN_PROTO_HDRS}
      ${GEN_GRPC_SRCS} ${GEN_GRPC_HDRS}
    )
    target_include_directories(telemetry_proto PUBLIC ${GEN_DIR})
    target_link_libraries(telemetry_proto PUBLIC protobuf::libprotobuf gRPC::grpc++)

    target_sources(physics_core PRIVATE src/cloud_grpc_sink.cpp)
    target_link_libraries(physics_core PUBLIC telemetry_proto)
    target_compile_definitions(physics_core PRIVATE SLIPSTREAM_ENABLE_GRPC)
  endif()
endif()

enable_testing()

set(PHYSICS_TEST_SOURCES
  tests/test_filters.cpp
  tests/test_transform.cpp
  tests/test_kinematics.cpp
  tests/test_engine.cpp
  tests/test_jitter_filter.cpp
  tests/test_profiling.cpp
  tests/test_cloud_streamer.cpp
)

foreach(test_src IN LISTS PHYSICS_TEST_SOURCES)
  get_filename_component(test_name ${test_src} NAME_WE)
  add_executable(${test_name} ${test_src})
  target_link_libraries(${test_name} PRIVATE physics_core)
  add_test(NAME ${test_name} COMMAND ${test_name})
endforeach()
