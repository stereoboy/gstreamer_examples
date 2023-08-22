FROM ubuntu:20.04

COPY ./.tmux.conf /root
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y vim tree htop tmux gdb net-tools
RUN apt-get install -y build-essential

# GStreamer
RUN apt-get install -y libgstreamer1.0-0 libgstreamer1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools
RUN apt-get install -y gstreamer1.0-doc
RUN apt-get install -y gstreamer1.0-plugins-base-apps libgstreamer-plugins-base1.0-dev
