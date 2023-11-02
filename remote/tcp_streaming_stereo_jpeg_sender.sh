#!/bin/sh

set -x

HOST=127.0.0.1
PORT0=5000
PORT1=5001

DEVICE0=/dev/video0
DEVICE1=/dev/video2
WIDTH=1280
HEIGHT=720
FRAMERATE=30/1

#
# references
#  - https://stackoverflow.com/questions/50549584/gstreamer-udpsink-udpsrc-versus-tcpserversink-tcpclientsrc
#  - https://gstreamer.freedesktop.org/documentation/rtp/rtpstreampay.html?gi-language=c#rtpstreampay-page
#
gst-launch-1.0 -tv  v4l2src device=${DEVICE0} ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! textoverlay text="${WIDTH}&#215;${HEIGHT}" valignment=top halignment=right ! tee name=t0 \
    t0. ! queue ! videorate ! jpegenc ! rtpjpegpay ! rtpstreampay ! tcpserversink host=${HOST} port=${PORT0} \
    t0. ! queue ! textoverlay text="local left" ! autovideosink \
                    v4l2src device=${DEVICE1} ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! textoverlay text="${WIDTH}&#215;${HEIGHT}" valignment=top halignment=right ! tee name=t1 \
    t1. ! queue ! videorate ! jpegenc ! rtpjpegpay ! rtpstreampay ! tcpserversink host=${HOST} port=${PORT1} \
    t1. ! queue ! textoverlay text="local right" ! autovideosink \
