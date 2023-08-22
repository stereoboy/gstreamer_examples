#!/bin/sh

#HOST=192.168.0.16
HOST=127.0.0.1

set -x

gst-launch-1.0 -v v4l2src device=/dev/video0 ! image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! tee name=t \
    t. ! queue ! jpegenc ! rtpjpegpay ! udpsink host=$HOST port=8554 \
    t. ! queue ! textoverlay text="local" ! autovideosink
