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
)

if (WIN32)
  target_sources(physics_core PRIVATE src/assetto_corsa_adapter_win.cpp)
  target_compile_definitions(physics_core PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
else()
  target_sources(physics_core PRIVATE src/assetto_corsa_adapter_stub.cpp)
endif()

add_executable(physics_tests tests/test_filters.cpp tests/test_transform.cpp tests/test_kinematics.cpp tests/test_engine.cpp)
target_link_libraries(physics_tests PRIVATE physics_core)

enable_testing()
add_test(NAME physics COMMAND physics_tests)
