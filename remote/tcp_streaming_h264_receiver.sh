#!/bin/sh

set -x

HOST=127.0.0.1

gst-launch-1.0 -tv tcpclientsrc host=$HOST port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink
