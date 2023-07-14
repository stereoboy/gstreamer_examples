#!/bin/sh
set -x

AUDIO_SRC=pulsesrc device=alsa_input.usb-046d_HD_Pro_Webcam_C920_9D5E927F-02.analog-stereo

timeout 15 gst-launch-1.0 -v $AUDIO_SRC ! audioconvert ! audioresample ! wavenc ! filesink location=../data/voice_with_noise.wav
