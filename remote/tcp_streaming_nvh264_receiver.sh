#!/bin/sh

set -x

HOST=127.0.0.1

# AGX
gst-launch-1.0 -tv tcpclientsrc host=$HOST port=5000 ! h264parse ! nvv4l2decoder ! nvvidconv ! autovideosink

# Desktop
#gst-launch-1.0 -tv tcpclientsrc host=$HOST port=5000 ! h264parse ! nvv4l2decoder ! nvvideoconvert ! autovideosink
