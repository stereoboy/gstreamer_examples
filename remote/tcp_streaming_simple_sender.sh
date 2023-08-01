#!/bin/sh

set -x

HOST=127.0.0.1

gst-launch-1.0 -tv v4l2src device=/dev/video0  ! image/jpeg, width=1920, height=1080, pixel-aspect-ratio=1/1, framerate=60/1 ! tcpserversink host=$HOST port=5000
