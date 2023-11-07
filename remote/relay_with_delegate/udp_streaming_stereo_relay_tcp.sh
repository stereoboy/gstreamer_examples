#!/bin/bash

set -x

PORT0=5000
PORT1=5001

WIDTH=1280
HEIGHT=720

#RELAY_HOST=172.31.13.19 # US server
RELAY_HOST=127.0.0.1
RELAY_PORT0=5002
RELAY_PORT1=5003

gst-launch-1.0 -tv \
    udpsrc  port=${PORT0} buffer-size=$((${WIDTH}*${HEIGHT}*3)) ! queue ! rtpstreampay ! tcpserversink host=${RELAY_HOST} port=${RELAY_PORT0} \
    udpsrc  port=${PORT1} buffer-size=$((${WIDTH}*${HEIGHT}*3)) ! queue ! rtpstreampay ! tcpserversink host=${RELAY_HOST} port=${RELAY_PORT1} \
