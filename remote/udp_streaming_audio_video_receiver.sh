#!/bin/sh

#gst-launch-1.0 -v -e udpsrc port=8554 !application/x-rtp, media=application, clock-rate=90000, encoding-name=X-GST ! rtpgstdepay ! avidemux name=demux \
#  demux. ! queue ! jpegdec ! autovideosink \
#  demux. ! queue ! alawdec ! autoaudiosink


gst-launch-1.0 udpsrc port=8555 ! 'application/x-rtp, media=(string)application, clock-rate=(int)90000, encoding-name=(string)X-GST, caps=(string)"YXVkaW8veC1hbGF3LCByYXRlPShpbnQpNDQxMDAsIGNoYW5uZWxzPShpbnQpMg\=\=", capsversion=(string)0' !\
  rtpgstdepay ! autoaudiosink \
  udpsrc port=8554 caps=application/x-rtp,media=video,encoding-name=JPEG ! rtpjpegdepay ! jpegdec ! autovideosink
