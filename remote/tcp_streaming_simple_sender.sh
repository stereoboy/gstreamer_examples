#!/bin/sh

set -x

HOST=127.0.0.1

gst-launch-1.0 -tv v4l2src device=/dev/video0  ! image/jpeg, width=1280, height=720, pixel-aspect-ratio=1/1, framerate=30/1 ! tee name=t \
    t. ! queue ! tcpserversink host=$HOST port=5000 \
    t. ! queue ! jpegdec ! textoverlay text="local" ! xvimagesink
