#!/bin/sh

set -x

#HOST=127.0.0.1
HOST=54.193.231.0 # US server

WIDTH=1280
HEIGHT=720

gst-launch-1.0 -tv v4l2src device=/dev/video0  ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! textoverlay text="${WIDTH}&#215;${HEIGHT}" valignment=top halignment=right ! tee name=t \
    t. ! queue ! jpegenc ! tcpclientsink host=$HOST port=5000 \
    t. ! queue ! textoverlay text="local" ! autovideosink
