#!/bin/bash

set -x

PORT0=5000
PORT1=5001
PORT2=5002
PORT3=5003

WIDTH=1280
HEIGHT=720

AUDIO_BUFFER_SIZE=100000

#RELAY_HOST=172.31.13.19 # US server
RELAY_HOST=127.0.0.1
RELAY_PORT0=5004
RELAY_PORT1=5005
RELAY_PORT2=5006
RELAY_PORT3=5007

gst-launch-1.0 -tv \
    udpsrc  port=${PORT0} buffer-size=$((${WIDTH}*${HEIGHT}*3)) ! queue ! rtpstreampay ! tcpserversink host=${RELAY_HOST} port=${RELAY_PORT0} \
    udpsrc  port=${PORT1} buffer-size=$((${WIDTH}*${HEIGHT}*3)) ! queue ! rtpstreampay ! tcpserversink host=${RELAY_HOST} port=${RELAY_PORT1} \
    udpsrc  port=${PORT2} buffer-size=${AUDIO_BUFFER_SIZE} ! queue ! rtpstreampay ! tcpserversink host=${RELAY_HOST} port=${RELAY_PORT2}