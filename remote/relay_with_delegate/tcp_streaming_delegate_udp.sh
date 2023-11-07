#!/bin/bash

set -x

#RELAY_HOST=172.31.13.19 # US server
RELAY_HOST=127.0.0.1
RELAY_PORT=5001

HOST=127.0.0.1
PORT=5002

gst-launch-1.0 -v tcpclientsrc host=${RELAY_HOST} port=${RELAY_PORT} ! application/x-rtp-stream,encoding-name=JPEG ! rtpstreamdepay ! udpsink host=${HOST} port=${PORT}

