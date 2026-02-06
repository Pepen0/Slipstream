cmake_minimum_required(VERSION 3.20)
project(slipstream_dashboard LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(PROTO_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../../shared/protos)
set(PROTO_FILE ${PROTO_ROOT}/dashboard/v1/dashboard.proto)

add_library(dashboard_core)
target_include_directories(dashboard_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_sources(dashboard_core PRIVATE
  src/dashboard_state.cpp
  src/logger.cpp
  src/session_store.cpp
)

add_executable(dashboard_core_tests tests/test_state.cpp)
target_link_libraries(dashboard_core_tests PRIVATE dashboard_core)

add_executable(dashboard_session_tests tests/test_session_store.cpp)
target_link_libraries(dashboard_session_tests PRIVATE dashboard_core)

enable_testing()
add_test(NAME dashboard_core COMMAND dashboard_core_tests)
add_test(NAME dashboard_sessions COMMAND dashboard_session_tests)

find_package(Protobuf CONFIG QUIET)
find_package(gRPC CONFIG QUIET)

if (Protobuf_FOUND AND gRPC_FOUND)
  message(STATUS "Building gRPC dashboard server")

  set(GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/_generated)
  set(GEN_SUBDIR ${GEN_DIR}/dashboard/v1)
  file(MAKE_DIRECTORY ${GEN_SUBDIR})

  set(PROTOC $<TARGET_FILE:protobuf::protoc>)
  set(GRPC_CPP_PLUGIN $<TARGET_FILE:gRPC::grpc_cpp_plugin>)

  set(GEN_PROTO_SRCS ${GEN_SUBDIR}/dashboard.pb.cc)
  set(GEN_PROTO_HDRS ${GEN_SUBDIR}/dashboard.pb.h)
  set(GEN_GRPC_SRCS ${GEN_SUBDIR}/dashboard.grpc.pb.cc)
  set(GEN_GRPC_HDRS ${GEN_SUBDIR}/dashboard.grpc.pb.h)

  add_custom_command(
    OUTPUT ${GEN_PROTO_SRCS} ${GEN_PROTO_HDRS}
    COMMAND ${PROTOC}
      --cpp_out=${GEN_DIR}
      -I ${PROTO_ROOT}
      ${PROTO_FILE}
    DEPENDS ${PROTO_FILE}
  )

  add_custom_command(
    OUTPUT ${GEN_GRPC_SRCS} ${GEN_GRPC_HDRS}
    COMMAND ${PROTOC}
      --grpc_out=${GEN_DIR}
      --plugin=protoc-gen-grpc=${GRPC_CPP_PLUGIN}
      -I ${PROTO_ROOT}
      ${PROTO_FILE}
    DEPENDS ${PROTO_FILE}
  )

  add_library(dashboard_proto
    ${GEN_PROTO_SRCS} ${GEN_PROTO_HDRS}
    ${GEN_GRPC_SRCS} ${GEN_GRPC_HDRS}
  )
  target_include_directories(dashboard_proto PUBLIC ${GEN_DIR})
  target_link_libraries(dashboard_proto PUBLIC protobuf::libprotobuf gRPC::grpc++)

  add_executable(dashboard_server src/dashboard_server.cpp src/main.cpp)
  target_include_directories(dashboard_server PRIVATE ${GEN_DIR})
  target_link_libraries(dashboard_server PRIVATE dashboard_core dashboard_proto)
endif()
