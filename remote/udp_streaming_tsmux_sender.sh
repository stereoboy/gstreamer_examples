#!/bin/sh

set -x

#
# references
#  - https://stackoverflow.com/questions/36564386/how-to-do-webcam-streaming-with-mpegtsmux-in-gstreamer
#  - https://stackoverflow.com/questions/74687061/creating-a-low-latency-rtp-mpegts-h-264-pipeline-with-gstreamer
#    - autovideosink sync=false
#  - https://gitlab.freedesktop.org/gstreamer/gst-plugins-bad/-/issues/875
#    - tsparse set-timestamps=true
#

#HOST=192.168.0.4
HOST=192.168.55.75
PORT=5000

DEVICE0=/dev/video4
DEVICE1=/dev/video6

WIDTH=640
HEIGHT=480

gst-launch-1.0 -vt -e v4l2src device=${DEVICE0} \
  ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=30/1 ! queue ! jpegdec \
  ! videoconvert \
  ! x264enc tune=zerolatency \
  ! mpegtsmux alignment=7 \
  ! tsparse set-timestamps=true \
  ! tsdemux \
  ! h264parse ! avdec_h264 \
  ! videoconvert ! fpsdisplaysink sync=false video-sink="autovideosink"

#gst-launch-1.0 -tv -e \
#  mpegtsmux name=mux ! udpsink host=${host} port=${port} \
#  v4l2src device=${device0} !image/jpeg, width=${width}, height=${height}, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! tee name=t0 \
#  t0. ! queue ! x264enc tune=zerolatency ! mux.sink_0 \
#  t0. ! queue ! textoverlay text="local left" ! autovideosink \
#  v4l2src device=${DEVICE1} !image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! tee name=t1 \
#  t1. ! queue ! jpegenc ! image/jpeg, framerate=30/1 ! rtpjpegpay ! application/x-rtp, payload=96 ! mux.sink_1 \
#  t1. ! queue ! textoverlay text="local right" ! autovideosink \


