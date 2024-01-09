#!/bin/sh

set -x

WIDTH=640
HEIGHT=480
DEVICE=/dev/video2
FILE=mono.mp4

#
# mp4mux works same way as qtmux
#
gst-launch-1.0 v4l2src -tv -e device=${DEVICE} ! image/jpeg, width=${WIDTH}, height=${HEIGHT} ! jpegdec ! tee name=t \
  t. ! queue ! x264enc tune=zerolatency ! qtmux ! filesink location=${FILE} \
  t. ! queue ! autovideosink
