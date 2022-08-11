#!/bin/sh
#
# references
# - https://stackoverflow.com/questions/35843178/streaming-audio-and-video-in-sync-for-mp4-container-using-gstreamer-framework
#

# baseline
#gst-launch-1.0 -v v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay !\
#  udpsink host=127.0.0.1 port=8554


#gst-launch-1.0 -v avimux name=mux ! rtpgstpay ! udpsink host=127.0.0.1 port=8555 \
#  v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=60/1 ! mux.video_0 \

  #pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo ! alawenc !  mux.\

# working, slow, frequently-discontinued
gst-launch-1.0 -v rtpmux name=mux ! udpsink host=127.0.0.1 port=8554 \
  v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=60/1 ! rtpjpegpay ! application/x-rtp, payload=26 ! mux.sink_1 \
  pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo ! alawenc ! rtpgstpay ! application/x-rtp, payload=96 ! mux.sink_2 \
