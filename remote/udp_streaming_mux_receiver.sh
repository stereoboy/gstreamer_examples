#!/bin/sh

#gst-launch-1.0 udpsrc port=8554 ! application/x-rtp,encoding-name=JPEG,payload=26 ! rtpjpegdepay ! jpegdec ! autovideosink



#gst-launch-1.0 -v udpsrc port=8554 caps="application/x-rtp" ! rtpptdemux name=demux \
#   ! queue ! rtpjpegdepay ! jpegdec ! autovideosink \

#
#
#
GST_DEBUG=5 gst-launch-1.0 -v udpsrc port=8554  caps="application/x-rtp" ! rtpssrcdemux name=demux \
  !   rtpjpegdepay ! jpegdec ! autovideosink \

#GST_DEBUG=3 gst-launch-1.0 -v udpsrc port=8554 caps="application/x-rtp" name=source ! rtpptdemux name=demux \
#  ! application/x-rtp,encoding-name=JPEG,payload=26 ! rtpjpegdepay ! jpegdec ! autovideosink \
#  demux.src_1 ! application/x-rtp,encoding-name=JPEG,payload=26 ! rtpjpegdepay ! jpegdec ! autovideosink \
