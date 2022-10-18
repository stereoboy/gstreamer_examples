#!/bin/sh

HOST=192.168.0.4

# baseline
#gst-launch-1.0 -v v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay !\
#  udpsink host=127.0.0.1 port=8554


gst-launch-1.0  rtpmux name=mux ! udpsink host=$HOST port=8553 \
  v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay ! application/x-rtp, payload=26 ! mux.sink_0 \
  v4l2src device=/dev/video1 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay ! application/x-rtp, payload=96 ! mux.sink_1 \

