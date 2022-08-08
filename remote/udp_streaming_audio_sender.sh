#!/bin/sh

# work, little slow
gst-launch-1.0 -v pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo !\
 alawenc ! rtppcmapay !application/x-rtp, payload=8, clock-rate=8000 !\
  udpsink host=127.0.0.1 port=8555

# runnable, not work well, very slow
#gst-launch-1.0 -v pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo !\
#  "audio/x-raw, format=(string)U8" ! rtpL8pay ! "application/x-rtp, media=audio, payload=96, clock-rate=90000, encoding-name=L8, channel=2" !\
#  udpsink host=127.0.0.1 port=8555

# work, slow
#gst-launch-1.0 -v pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo !\
#  avenc_ac3 ! rtpac3pay ! \
#  udpsink host=127.0.0.1 port=8555

#gst-launch-1.0 -v pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo !\
#  audio/x-raw, format=S16LE, rate=8000 ! \
#  alawenc ! rtppcmapay !application/x-rtp, media=audio, payload=96, clock-rate=90000, encoding-name=PCMA !\
#  udpsink host=127.0.0.1 port=8555

#  alawenc ! rtppcmapay !application/x-rtp, payload=8, clock-rate=8000 !\
