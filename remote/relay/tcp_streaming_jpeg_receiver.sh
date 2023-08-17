#!/bin/sh

set -x

#HOST=127.0.0.1
HOST=54.193.231.0 # US server

gst-launch-1.0 -tv tcpclientsrc host=$HOST port=5001 ! jpegdec ! autovideosink
