#!/bin/sh

set -x

FILE=stereo.mp4

#gst-launch-1.0 -tv -e uridecodebin name=u uri=file://`pwd`/stereo.mp4 ! video/x-raw ! queue ! videoconvert ! autovideosink \
#  u. ! video/x-raw ! queue ! videoconvert ! autovideosink

gst-launch-1.0 -tv -e filesrc location=${FILE} ! qtdemux name=demux  \
   demux.video_0 ! queue ! decodebin ! videoconvert ! videoscale ! autovideosink \
   demux.video_1 ! queue ! decodebin ! videoconvert ! videoscale ! autovideosink \

