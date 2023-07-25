#!/bin/sh
set -x

AUDIO_SRC="pulsesrc device=alsa_input.usb-046d_HD_Pro_Webcam_C920_9D5E927F-02.analog-stereo"
#AUDIO_SRC="pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo"

gst-launch-1.0 -v $AUDIO_SRC ! audioconvert ! audioresample ! \
    autoaudiosink
