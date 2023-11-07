#!/bin/bash

PORT=5000

WIDTH=1280
HEIGHT=720

RELAY_HOST=127.0.0.1
RELAY_PORT=5001

gst-launch-1.0 -v udpsrc  port=${PORT} buffer-size=$((${WIDTH}*${HEIGHT}*3)) ! queue ! rtpstreampay ! tcpserversink host=${RELAY_HOST} port=${RELAY_PORT}