#!/bin/sh

set -x

PORT=5000

WIDTH=640
HEIGHT=480

gst-launch-1.0 -vt -e udpsrc port=${PORT} buffer-size=$((${WIDTH}*${HEIGHT})) \
  ! tsparse \
  ! tsdemux \
  ! h264parse \
  ! avdec_h264 \
  ! videoconvert \
  ! autovideosink

#gst-launch-1.0 -tv -e \
#    udpsrc port=${PORT} buffer-size=$((${WIDTH}*${HEIGHT})) ! \
#    application/x-rtp,encoding-name=JPEG,media=video,clock-rate=90000 ! \
#    rtpjitterbuffer latency=200 ! rtpptdemux name=demux \
#    demux. ! application/x-rtp,encoding-name=JPEG,media=video,clock-rate=90000,payload=26 ! queue ! rtpjpegdepay ! jpegparse ! jpegdec ! textoverlay text="remote left" ! autovideosink \
#    demux. ! application/x-rtp,encoding-name=JPEG,media=video,clock-rate=90000,payload=96 ! queue ! rtpjpegdepay ! jpegparse ! jpegdec ! textoverlay text="remote right" ! autovideosink \
#
