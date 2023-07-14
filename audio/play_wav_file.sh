#!/bin/sh
set -x

#gst-launch-1.0 -v filesrc location=../data/voice_with_noise.wav ! decodebin ! audioconvert ! autoaudiosink

gst-launch-1.0 -v filesrc location=../data/voice_with_noise.wav ! decodebin ! audioconvert ! tee name=t \
  t. ! queue ! autoaudiosink \
  t. ! queue ! wavescope ! ximagesink
