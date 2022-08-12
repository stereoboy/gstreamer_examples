#!/bin/sh

xterm +hold -title video0 -e \
gst-launch-1.0 udpsrc port=8553 caps=application/x-rtp,media=video,encoding-name=JPEG ! rtpjpegdepay ! jpegdec ! autovideosink &

xterm +hold -title video1 -e \
gst-launch-1.0 udpsrc port=8554 caps=application/x-rtp,media=video,encoding-name=JPEG ! rtpjpegdepay ! jpegdec ! autovideosink &

xterm +hold -title video2 -e \
gst-launch-1.0 udpsrc port=8555 caps=application/x-rtp,media=video,encoding-name=JPEG ! rtpjpegdepay ! jpegdec ! autovideosink &


xterm +hold -title audio -e \
gst-launch-1.0 udpsrc port=8556 ! 'application/x-rtp, media=(string)application, clock-rate=(int)90000, encoding-name=(string)X-GST, caps=(string)"YXVkaW8veC1hbGF3LCByYXRlPShpbnQpNDQxMDAsIGNoYW5uZWxzPShpbnQpMg\=\=", capsversion=(string)0' !\
  rtpgstdepay ! autoaudiosink
