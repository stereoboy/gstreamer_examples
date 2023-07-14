#!/bin/sh
set -x

#gst-launch-1.0 -v filesrc location=../data/voice_with_noise.wav ! decodebin ! audioconvert ! tee name=t \
#  t. ! queue ! wavescope ! textoverlay text="Raw" ! ximagesink \
#  t. ! queue ! audioresample ! webrtcdsp ! webrtcechoprobe ! audioconvert ! wavescope ! textoverlay text="NR" ! ximagesink


gst-launch-1.0 -v compositor name=comp sink_1::xpos=400 ! videoconvert ! ximagesink \
  filesrc location=../data/voice_with_noise.wav ! decodebin ! audioconvert ! tee name=t \
  t. ! queue ! wavescope ! textoverlay text="Raw" ! comp. \
  t. ! queue ! audioresample ! webrtcdsp ! webrtcechoprobe ! audioconvert ! wavescope ! textoverlay text="NR" ! comp.
