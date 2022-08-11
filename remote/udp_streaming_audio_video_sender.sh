#!/bin/sh

#gst-launch-1.0 -v -e avimux name=mux ! rtpgstpay ! application/x-rtp,media=application,payload=96,clock-rate=90000,encoding-name=X-GST ! udpsink host=127.0.0.1 port=8554 \
#  v4l2src device=/dev/video0 ! image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=60/1 !\
#  queue ! mux.video_0 \
#  pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo ! alawenc ! queue ! mux.audio_0

#gst-launch-1.0 -v -e mpegtsmux name=mux ! video/mpegts, packetsize=188, systemstrame=true ! rtpmp2tpay ! application/x-rtp,media=video,payload=33,clock-rate=90000,encoding-name=MP2T ! udpsink host=127.0.0.1 port=8554 \
#  v4l2src device=/dev/video0 ! video/x-raw, format=YUY2, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! videoconvert !\
#  x264enc ! mux. \

#gst-launch-1.0 -e v4l2src device=/dev/video0 ! image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=60/1 ! jpegdec ! videoconvert ! mkv. autoaudiosrc ! queue ! audioconvert ! mkv. matroskamux name=mkv ! filesink location=test.mkv sync=false


#gst-launch-1.0  rtpmux name=mux ! udpsink host=127.0.0.1 port=8554 \
#  v4l2src device=/dev/video2 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=60/1 ! rtpjpegpay ! application/x-rtp, payload=26 ! mux.sink_1 \
#  pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo !\
#  alawenc ! rtpgstpay ! mux.sink_2 \


gst-launch-1.0 -v pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo !\
  alawenc ! rtpgstpay !\
  udpsink host=127.0.0.1 port=8555 \
  v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=60/1 ! rtpjpegpay !\
  udpsink host=127.0.0.1 port=8554
