#!/bin/sh

#HOST=192.168.0.4
HOST=192.168.55.75
PORT=5000
# baseline
#gst-launch-1.0 -v v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay !\
#  udpsink host=127.0.0.1 port=8554

DEVICE0=/dev/video4
DEVICE1=/dev/video6

WIDTH=640
HEIGHT=480

gst-launch-1.0 -tv -e \
  rtpmux name=mux ! udpsink host=${HOST} port=${PORT} \
  v4l2src device=${DEVICE0} !image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! tee name=t0 \
  t0. ! queue ! jpegenc ! image/jpeg, framerate=30/1 ! rtpjpegpay ! application/x-rtp, payload=26 ! mux.sink_0 \
  t0. ! queue ! textoverlay text="local left" ! autovideosink \
  v4l2src device=${DEVICE1} !image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! tee name=t1 \
  t1. ! queue ! jpegenc ! image/jpeg, framerate=30/1 ! rtpjpegpay ! application/x-rtp, payload=96 ! mux.sink_1 \
  t1. ! queue ! textoverlay text="local right" ! autovideosink \


