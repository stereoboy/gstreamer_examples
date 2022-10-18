#!/bin/sh

HOST=192.168.0.4

set -x

gst-launch-1.0 -v v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay !\
  udpsink host=$HOST port=8554
