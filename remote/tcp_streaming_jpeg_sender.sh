#!/bin/sh

set -x

HOST=127.0.0.1

WIDTH=1280
HEIGHT=720
#
# references
#  - fpsdiplaysink
#    - https://gstreamer.freedesktop.org/documentation/debugutilsbad/fpsdisplaysink.html?gi-language=c
#
gst-launch-1.0 -tv v4l2src device=/dev/video0 ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! textoverlay text="${WIDTH}&#215;${HEIGHT}" valignment=top halignment=right ! tee name=t \
    t. ! queue ! jpegenc ! tcpserversink host=$HOST port=5000 \
    t. ! queue ! textoverlay text="local" ! autovideosink

#
# references
#  - https://stackoverflow.com/questions/50549584/gstreamer-udpsink-udpsrc-versus-tcpserversink-tcpclientsrc
#  - https://gstreamer.freedesktop.org/documentation/rtp/rtpstreampay.html?gi-language=c#rtpstreampay-page
#
#gst-launch-1.0 -tv v4l2src device=/dev/video0 ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! textoverlay text="${WIDTH}&#215;${HEIGHT}" valignment=top halignment=right ! tee name=t \
#    t. ! queue ! videorate ! jpegenc ! rtpjpegpay ! rtpstreampay ! tcpserversink host=$HOST port=5000 \
#    t. ! queue ! textoverlay text="local" ! autovideosink \
