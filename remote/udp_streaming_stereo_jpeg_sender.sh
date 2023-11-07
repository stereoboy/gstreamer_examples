#!/bin/sh

set -x

#HOST=54.193.231.0 # US server
HOST=127.0.0.1
PORT0=5000
PORT1=5001

DEVICE0=/dev/video0
DEVICE1=/dev/video2
WIDTH=1280
HEIGHT=720
FRAMERATE=30/1

gst-launch-1.0 -tv \
    v4l2src device=${DEVICE0} ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=${FRAMERATE} ! jpegdec ! timeoverlay ! tee name=t0 \
    t0. ! queue ! jpegenc ! rtpjpegpay ! udpsink host=${HOST} port=${PORT0} \
    t0. ! queue ! textoverlay text="local left" ! autovideosink \
    v4l2src device=${DEVICE1} ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=${FRAMERATE} ! jpegdec ! timeoverlay ! tee name=t1 \
    t1. ! queue ! jpegenc ! rtpjpegpay ! udpsink host=${HOST} port=${PORT1} \
    t1. ! queue ! textoverlay text="local right" ! autovideosink
