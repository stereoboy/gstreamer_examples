#!/bin/sh

set -x

FILE=mono.mp4

gst-launch-1.0 -tv -e filesrc location=${FILE} ! qtdemux ! \
   queue ! decodebin ! videoconvert ! videoscale ! autovideosink \
