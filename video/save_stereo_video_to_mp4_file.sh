#!/bin/sh

set -x

WIDTH=640
HEIGHT=480
DEVICE0=/dev/video4
DEVICE1=/dev/video6
FILE=stereo.mp4

#
# mp4mux works same way as qtmux
#
gst-launch-1.0 -tv -e qtmux name=m ! filesink location=${FILE} \
  v4l2src device=${DEVICE0} ! image/jpeg, width=${WIDTH}, height=${HEIGHT} ! jpegdec ! tee name=t1 \
  t1. ! queue ! x264enc tune=zerolatency ! m.video_1 \
  t1. ! queue ! autovideosink name=video1 \
  v4l2src device=${DEVICE1} ! image/jpeg, width=${WIDTH}, height=${HEIGHT} ! jpegdec ! tee name=t2 \
  t2. ! queue ! x264enc tune=zerolatency ! m.video_2 \
  t2. ! queue ! autovideosink name=video2

