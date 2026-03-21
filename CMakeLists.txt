cmake_minimum_required(VERSION 3.16)
project(war30k_adventure VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(SDL2 REQUIRED)

add_executable(
  war30k_adventure
  src/main.cpp
  src/game.cpp
  src/core/common.cpp
  src/core/world.cpp
  src/core/render.cpp
  src/core/animated_sprite.cpp
)

target_include_directories(war30k_adventure PRIVATE include)
target_link_libraries(war30k_adventure PRIVATE SDL2::SDL2)

if(TARGET SDL2::SDL2main)
  target_link_libraries(war30k_adventure PRIVATE SDL2::SDL2main)
endif()
