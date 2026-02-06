cmake_minimum_required(VERSION 3.20)
project(slipstream_heartbeat LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(heartbeat_core)
target_include_directories(heartbeat_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_sources(heartbeat_core PRIVATE
  src/protocol.cpp
  src/crc16.cpp
)

if (WIN32)
  target_sources(heartbeat_core PRIVATE src/serial_port_win.cpp)
  target_compile_definitions(heartbeat_core PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
else()
  target_sources(heartbeat_core PRIVATE src/serial_port_posix.cpp)
endif()

add_executable(heartbeat_sender src/main.cpp)
target_link_libraries(heartbeat_sender PRIVATE heartbeat_core)

add_executable(heartbeat_tests tests/test_protocol.cpp)
target_link_libraries(heartbeat_tests PRIVATE heartbeat_core)

add_executable(heartbeat_batch_tests tests/test_batcher.cpp)
target_link_libraries(heartbeat_batch_tests PRIVATE heartbeat_core)

enable_testing()
add_test(NAME protocol COMMAND heartbeat_tests)
add_test(NAME batcher COMMAND heartbeat_batch_tests)
