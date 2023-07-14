#!/bin/sh
set -x

gst-launch-1.0 -v filesrc location=../data/voice_with_noise.wav ! decodebin ! audioconvert ! autoaudiosink
