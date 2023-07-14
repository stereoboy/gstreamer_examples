#!/bin/sh
set -x

#gst-launch-1.0 -v filesrc location=../data/voice_with_noise.wav ! decodebin ! audioconvert ! \
#  audiocheblimit mode=low-pass cutoff=4000 type=1 ! \
#  audiocheblimit mode=high-pass cutoff=200 type=1 ! \
#  autoaudiosink


gst-launch-1.0 -v filesrc location=../data/voice_with_noise.wav ! decodebin ! audioconvert ! audioresample ! \
    webrtcdsp ! webrtcechoprobe ! \
    audioconvert ! audioresample ! autoaudiosink
