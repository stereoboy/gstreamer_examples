#!/bin/sh

set -x

HOST=127.0.0.1
PORT=5000

#gst-launch-1.0 -tv tcpclientsrc host=${HOST} port=${PORT} ! jpegdec ! autovideosink

#
# references
#  - https://stackoverflow.com/questions/50549584/gstreamer-udpsink-udpsrc-versus-tcpserversink-tcpclientsrc
#  - https://gstreamer.freedesktop.org/documentation/rtp/rtpstreampay.html?gi-language=c#rtpstreampay-page
#
gst-launch-1.0 -tv tcpclientsrc host=${HOST} port=${PORT} ! application/x-rtp-stream,encoding-name=JPEG ! rtpstreamdepay ! rtpjpegdepay ! queue ! jpegdec ! autovideosink
