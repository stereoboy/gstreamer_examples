FROM ubuntu:22.04

COPY ./.tmux.conf /root
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y vim tree htop tmux gdb net-tools
RUN apt-get install -y build-essential

###########################################################
# GStreamer
RUN apt-get install -y libgstreamer1.0-0 libgstreamer1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools
#RUN apt-get install -y gstreamer1.0-doc
RUN apt-get install -y gstreamer1.0-plugins-base-apps libgstreamer-plugins-base1.0-dev

###########################################################
# Audio
#
# reference for audio sound card
#  - https://askubuntu.com/questions/70560/why-am-i-getting-this-connection-to-pulseaudio-failed-error
RUN apt-get install -y pulseaudio

#
# rerefece for pulseaudio
#  - https://stackoverflow.com/questions/66775654/how-can-i-make-pulseaudio-run-as-root
RUN adduser root pulse-access

# GStreamer
RUN apt-get install -y gstreamer1.0-pulseaudio

###########################################################
# Gst Python3
RUN apt-get install -y libcairo2-dev libxt-dev libgirepository1.0-dev
RUN apt-get install -y python3-pip
RUN python3 -m pip install pycairo PyGObject
