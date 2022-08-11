#!/bin/sh

# working, slow
#gst-launch-1.0 udpsrc port=8555 !application/x-rtp, media=audio, payload=8, clock-rate=8000 !\
#  rtppcmadepay ! autoaudiosink

# working, high-quality, little slow
gst-launch-1.0 udpsrc port=8555 ! 'application/x-rtp, media=(string)application, clock-rate=(int)90000, encoding-name=(string)X-GST, caps=(string)"YXVkaW8veC1hbGF3LCByYXRlPShpbnQpNDQxMDAsIGNoYW5uZWxzPShpbnQpMg\=\=", capsversion=(string)0' !\
  rtpgstdepay ! autoaudiosink

# runnable, not work well, very slow
#gst-launch-1.0 udpsrc port=8555 !application/x-rtp, media=audio, encoding-name=L8, payload=96, clock-rate=90000 !\
#  rtpL8depay ! autoaudiosink

# working, slow
#gst-launch-1.0 udpsrc port=8555 ! application/x-rtp, media=audio, clock-rate=44100, encoding-name=AC3 !\
#  rtpac3depay ! a52dec ! pulsesink

#################################################################################################
#
# references https://marc.info/?l=gstreamer-devel&m=150650921723890&w=2
# working, slow
#gst-launch-1.0 -v udpsrc port=8555 !application/x-rtp, media=audio, clock-rate=44100, encoding-name=MP4A-LATM, config=40002410adca00 ! rtpjitterbuffer !\
#  rtpmp4adepay !  avdec_aac ! audioconvert ! autoaudiosink
#################################################################################################

#################################################################################################
#gst-launch-1.0 -v udpsrc port=8555 !application/x-rtp, media=audio, payload=96, clock-rate=90000, encoding-name=MPA !\
#  rtpmpadepay !  avdec_mp3 ! audioconvert ! autoaudiosink
#################################################################################################
#gst-launch-1.0 udpsrc port=8555 !application/x-rtp, media=audio, payload=96, clock-rate=8000 !\
#  rtppcmadepay ! autoaudiosink
