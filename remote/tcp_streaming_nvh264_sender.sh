#!/bin/sh

set -x

HOST=127.0.0.1

gst-launch-1.0 -tv v4l2src device=/dev/video0  ! image/jpeg, width=320, height=240, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! tee name=t \
    t. ! queue ! nvvidconv flip-method=0 ! nvv4l2h264enc insert-sps-pps=true bitrate=16000000 ! tcpserversink host=$HOST port=5000 \
    t. ! queue ! textoverlay text="local" ! autovideosink
