#!/bin/sh

set -x

#HOST=54.193.231.0 # US server
HOST=127.0.0.1
PORT=5000

DEVICE=/dev/video0
WIDTH=1280
HEIGHT=720
FRAMERATE=30/1

gst-launch-1.0 -tv v4l2src device=${DEVICE} ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=${FRAMERATE} ! jpegdec ! timeoverlay ! tee name=t \
    t. ! queue ! jpegenc ! rtpjpegpay ! udpsink host=${HOST} port=${PORT} \
    t. ! queue ! textoverlay text="local" ! autovideosink
