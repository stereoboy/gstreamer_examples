FROM ubuntu:20.04

COPY ./.tmux.conf /root
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y vim tree htop tmux gdb net-tools
RUN apt-get install -y build-essential

# GStreamer
RUN apt-get install -y libgstreamer1.0-dev gstreamer1.0-plugins-base-apps
