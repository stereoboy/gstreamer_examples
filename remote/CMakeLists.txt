cmake_minimum_required(VERSION 3.10)

project(gstreamer_remote_samples C) #Project name

find_package(PkgConfig) #finding pkg-config is a helper tool

set (CMAKE_C_FLAGS "-g")

#using pkg-config to getting Gstreamer
pkg_check_modules(GSTREAMER REQUIRED gstreamer-1.0)


#including GStreamer header files directory
include_directories(
    ./include
    ${GSTREAMER_INCLUDE_DIRS}
)

#linking GStreamer library directory
link_directories(
    ${GSTREAMER_LIBRARY_DIRS}
)

#building target executable
add_executable(udp_streaming_simple_receiver udp_streaming_simple_receiver.c)

#linking Gstreamer library with target executable
target_link_libraries(udp_streaming_simple_receiver ${GSTREAMER_LIBRARIES})


add_executable(udp_streaming_mux_receiver udp_streaming_mux_receiver.c)

#linking Gstreamer library with target executable
target_link_libraries(udp_streaming_mux_receiver ${GSTREAMER_LIBRARIES})
