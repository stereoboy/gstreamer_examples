#!/bin/sh

set -x

#HOST=54.193.231.0 # US server
HOST=127.0.0.1
PORT=5000

DEVICE0=/dev/video0
DEVICE1=/dev/video2
WIDTH=1280
HEIGHT=720
FRAMERATE=30/1

gst-launch-1.0 -tv -e \
    compositor name=comp sink_1::ypos=${HEIGHT} ! video/x-raw ! tee name=t \
    v4l2src device=${DEVICE0} ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=${FRAMERATE} ! jpegdec ! \
        timeoverlay ! textoverlay text="${WIDTH}&#215;${HEIGHT}" valignment=top halignment=right ! comp.sink_0 \
    v4l2src device=${DEVICE1} ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=${FRAMERATE} ! jpegdec ! \
        timeoverlay ! textoverlay text="${WIDTH}&#215;${HEIGHT}" valignment=top halignment=right ! comp.sink_1 \
    t. ! queue ! jpegenc ! rtpjpegpay ! udpsink host=${HOST} port=${PORT} \
    t. ! queue ! textoverlay text="local" ! fpsdisplaysink video-sink="autovideosink" \
