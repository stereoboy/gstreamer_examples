#!/bin/sh

# working, slow
gst-launch-1.0 udpsrc port=8555 !application/x-rtp, media=audio, payload=8, clock-rate=8000 !\
  rtppcmadepay ! autoaudiosink

# runnable, not work well, very slow
#gst-launch-1.0 udpsrc port=8555 !application/x-rtp, media=audio, encoding-name=L8, payload=96, clock-rate=90000 !\
#  rtpL8depay ! autoaudiosink

# working, slow
#gst-launch-1.0 udpsrc port=8555 ! application/x-rtp, media=audio, clock-rate=44100, encoding-name=AC3 !\
#  rtpac3depay ! a52dec ! pulsesink

#gst-launch-1.0 udpsrc port=8555 !application/x-rtp, media=audio, payload=96, clock-rate=8000 !\
#  rtppcmadepay ! autoaudiosink
