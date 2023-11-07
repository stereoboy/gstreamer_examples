#!/bin/bash

set -x

#RELAY_HOST=172.31.13.19 # US server
RELAY_HOST=127.0.0.1
RELAY_PORT0=5002
RELAY_PORT1=5003

HOST=127.0.0.1
PORT0=5004
PORT1=5005

gst-launch-1.0 -tv \
    tcpclientsrc host=${RELAY_HOST} port=${RELAY_PORT0} ! application/x-rtp-stream,encoding-name=JPEG ! rtpstreamdepay ! udpsink host=${HOST} port=${PORT0} \
    tcpclientsrc host=${RELAY_HOST} port=${RELAY_PORT1} ! application/x-rtp-stream,encoding-name=JPEG ! rtpstreamdepay ! udpsink host=${HOST} port=${PORT1} \
