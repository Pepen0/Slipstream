cmake_minimum_required(VERSION 3.20)
project(slipstream_physics LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
option(SLIPSTREAM_BUILD_GAME_ADAPTER_PLUGINS "Build runtime-loadable game adapter plugins" ON)

add_library(physics_core)
set_target_properties(physics_core PROPERTIES POSITION_INDEPENDENT_CODE ON)
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
  src/coordinate_normalizer.cpp
  src/game_adapter.cpp
  src/game_adapter_plugin.cpp
  src/game_adapter_registry.cpp
  src/iracing_adapter_stub.cpp
  src/universal_game_adapter.cpp
  src/f1_udp_adapter.cpp
)

if (WIN32)
  target_sources(physics_core PRIVATE src/assetto_corsa_adapter_win.cpp)
  target_compile_definitions(physics_core PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
  target_link_libraries(physics_core PRIVATE ws2_32)
else()
  target_sources(physics_core PRIVATE src/assetto_corsa_adapter_stub.cpp)
endif()

if (UNIX AND NOT APPLE)
  target_link_libraries(physics_core PRIVATE dl)
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
    set_target_properties(telemetry_proto PROPERTIES POSITION_INDEPENDENT_CODE ON)
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
  tests/test_coordinate_normalizer.cpp
  tests/test_f1_udp_adapter.cpp
  tests/test_plugin_loader.cpp
  tests/test_universal_game_adapter.cpp
)

foreach(test_src IN LISTS PHYSICS_TEST_SOURCES)
  get_filename_component(test_name ${test_src} NAME_WE)
  add_executable(${test_name} ${test_src})
  target_link_libraries(${test_name} PRIVATE physics_core)
  add_test(NAME ${test_name} COMMAND ${test_name})
endforeach()

add_executable(test_iracing_adapter_plugin
  tests/test_iracing_adapter_plugin.cpp
  plugins/iracing/src/iracing_adapter_plugin.cpp
)
target_include_directories(test_iracing_adapter_plugin PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR}/plugins/iracing/include
)
target_link_libraries(test_iracing_adapter_plugin PRIVATE physics_core)
add_test(NAME test_iracing_adapter_plugin COMMAND test_iracing_adapter_plugin)

if (SLIPSTREAM_BUILD_GAME_ADAPTER_PLUGINS)
  add_library(iracing_game_adapter_plugin MODULE
    plugins/iracing/src/iracing_adapter_plugin.cpp
  )
  target_include_directories(iracing_game_adapter_plugin PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/plugins/iracing/include
  )
  target_link_libraries(iracing_game_adapter_plugin PRIVATE physics_core)
  set_target_properties(iracing_game_adapter_plugin PROPERTIES
    OUTPUT_NAME "iracing_game_adapter_plugin"
    PREFIX ""
  )
  if (WIN32)
    target_compile_definitions(iracing_game_adapter_plugin PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
  endif()

  add_executable(test_iracing_plugin_loader_integration
    tests/test_iracing_plugin_loader_integration.cpp
  )
  target_include_directories(test_iracing_plugin_loader_integration PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
  )
  target_link_libraries(test_iracing_plugin_loader_integration PRIVATE physics_core)
  target_compile_definitions(test_iracing_plugin_loader_integration PRIVATE
    SLIPSTREAM_IRACING_PLUGIN_PATH="$<TARGET_FILE:iracing_game_adapter_plugin>"
  )
  add_dependencies(test_iracing_plugin_loader_integration iracing_game_adapter_plugin)
  add_test(NAME test_iracing_plugin_loader_integration COMMAND test_iracing_plugin_loader_integration)

  if (WIN32)
    add_executable(test_iracing_live_probe_smoke_win
      tests/test_iracing_live_probe_smoke_win.cpp
    )
    target_include_directories(test_iracing_live_probe_smoke_win PRIVATE
      ${CMAKE_CURRENT_SOURCE_DIR}/include
    )
    target_link_libraries(test_iracing_live_probe_smoke_win PRIVATE physics_core)
    target_compile_definitions(test_iracing_live_probe_smoke_win PRIVATE
      SLIPSTREAM_IRACING_PLUGIN_PATH="$<TARGET_FILE:iracing_game_adapter_plugin>"
      NOMINMAX
      WIN32_LEAN_AND_MEAN
    )
    add_dependencies(test_iracing_live_probe_smoke_win iracing_game_adapter_plugin)
    add_test(NAME test_iracing_live_probe_smoke_win COMMAND test_iracing_live_probe_smoke_win)
    set_tests_properties(test_iracing_live_probe_smoke_win PROPERTIES
      LABELS "smoke;iracing;windows"
      TIMEOUT 45
    )
  endif()
endif()
