#!/bin/sh

#gst-launch-1.0 udpsrc port=8554 ! application/x-rtp,encoding-name=JPEG,payload=26 ! rtpjpegdepay ! jpegdec ! autovideosink



gst-launch-1.0 -v  \
  udpsrc port=8554 caps=application/x-rtp,encoding-name=JPEG,media=video,clock-rate=90000 ! rtpptdemux name=demux \
   demux. ! queue ! rtpjpegdepay ! jpegdec ! autovideosink \
   demux. ! queue ! rtpjpegdepay ! jpegdec ! autovideosink \

