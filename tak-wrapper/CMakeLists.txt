cmake_minimum_required(VERSION 3.10)
project(TAKWrapper)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(OpenSSL REQUIRED)
find_package(Threads REQUIRED)

# Create common library
add_library(cot_common STATIC cot_common.cpp)
target_include_directories(cot_common PUBLIC .)
target_link_libraries(cot_common 
    OpenSSL::SSL 
    OpenSSL::Crypto 
    Threads::Threads
)

# Add executables
add_executable(cot_injector cot_injector.cpp)
add_executable(cot_listener cot_listener.cpp)

# Link common library to executables
target_link_libraries(cot_injector 
    cot_common
    OpenSSL::SSL 
    OpenSSL::Crypto 
    Threads::Threads
)

target_link_libraries(cot_listener 
    cot_common
    OpenSSL::SSL 
    OpenSSL::Crypto 
    Threads::Threads
)

# Compiler-specific options
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(cot_common PRIVATE -Wall -Wextra -Wpedantic)
    target_compile_options(cot_injector PRIVATE -Wall -Wextra -Wpedantic)
    target_compile_options(cot_listener PRIVATE -Wall -Wextra -Wpedantic)
endif()

# Debug build options
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -DDEBUG")

# Release build optimizations
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O2")

# Install targets
install(TARGETS cot_injector cot_listener DESTINATION bin)