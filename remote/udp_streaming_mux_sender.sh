#!/bin/sh

# baseline
#gst-launch-1.0 -v v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay !\
#  udpsink host=127.0.0.1 port=8554


gst-launch-1.0 -v rtpmux name=mux ! udpsink host=127.0.0.1 port=8554 \
  v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay ! mux.sink_0 \
  v4l2src device=/dev/video1 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay ! mux.sink_1 \



