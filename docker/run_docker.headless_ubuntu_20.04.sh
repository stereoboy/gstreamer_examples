#!/bin/bash

set -x
#
# references
#  - https://stackoverflow.com/questions/24225647/docker-a-way-to-give-access-to-a-host-usb-or-serial-device
#
#        --device /dev/bus/usb \ for flir camera
#        --device-cgroup-rule='c 188:* rmw' \ for flir camera
#        --device-cgroup-rule='c 189:* rmw' \ for usb2serial
#        --device-cgroup-rule='c 81:* rmw' \ for webcam
#



docker run  --rm -it \
        --net=host \
        --privileged \
        --device /dev/bus/usb \
        --device-cgroup-rule='c 188:* rmw' \
        --device-cgroup-rule='c 189:* rmw' \
        --device-cgroup-rule='c 81:* rmw' \
        -v /run/udev:/run/udev:ro \
        -v /dev:/dev \
        -v /home/$USER:/home/$USER \
        -w /home/$USER \
        --name gst_ubuntu_20.04 \
   gst_ubuntu_20.04:latest
