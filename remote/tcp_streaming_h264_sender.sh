#!/bin/sh

set -x

HOST=127.0.0.1

gst-launch-1.0 -tv v4l2src device=/dev/video0  ! image/jpeg, width=176, height=144, pixel-aspect-ratio=1/1, framerate=10/1 ! jpegdec ! timeoverlay ! tee name=t \
    t. ! queue ! videoconvert !  x264enc tune=zerolatency bitrate=16000000 speed-preset=superfast ! tcpserversink host=$HOST port=5000 \
    t. ! queue ! textoverlay text="local" ! autovideosink
