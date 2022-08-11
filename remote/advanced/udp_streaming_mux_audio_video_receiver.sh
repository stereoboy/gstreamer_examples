#!/bin/sh

#gst-launch-1.0 udpsrc port=8554 ! application/x-rtp,encoding-name=JPEG,payload=26 ! rtpjpegdepay ! jpegdec ! autovideosink


# working, slow, frequently-discontinued
gst-launch-1.0 -v  \
  udpsrc port=8554 caps=application/x-rtp ! queue ! rtpptdemux name=demux \
   demux. ! application/x-rtp,encoding-name=JPEG, media=video, clock-rate=90000, payload=26 ! queue ! rtpjpegdepay ! jpegdec ! autovideosink \
   demux. ! 'application/x-rtp, media=(string)application, clock-rate=(int)90000, encoding-name=(string)X-GST, caps=(string)"YXVkaW8veC1hbGF3LCByYXRlPShpbnQpNDQxMDAsIGNoYW5uZWxzPShpbnQpMg\=\=", capsversion=(string)0, payload=(int)96' ! queue ! \
  rtpgstdepay ! autoaudiosink

