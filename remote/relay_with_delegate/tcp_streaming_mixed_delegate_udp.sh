#!/bin/bash

set -x

AUDIO_BUFFER_SIZE=100000

#RELAY_HOST=172.31.13.19 # US server
# RELAY_HOST=127.0.0.1
RELAY_HOST=192.168.0.2
RELAY_PORT0=5004
RELAY_PORT1=5005
RELAY_PORT2=5006
RELAY_PORT3=5007

HOST=127.0.0.1
PORT0=5008
PORT1=5009
PORT2=5010
PORT3=5011

gst-launch-1.0 -tv \
    tcpclientsrc host=${RELAY_HOST} port=${RELAY_PORT0} ! application/x-rtp-stream,encoding-name=JPEG ! rtpstreamdepay ! udpsink host=${HOST} port=${PORT0} \
    tcpclientsrc host=${RELAY_HOST} port=${RELAY_PORT1} ! application/x-rtp-stream,encoding-name=JPEG ! rtpstreamdepay ! udpsink host=${HOST} port=${PORT1} \
    tcpclientsrc host=${RELAY_HOST} port=${RELAY_PORT2} ! application/x-rtp-stream,media=audio, clock-rate=44100, encoding-name=L16, channels=2, channel-mask=0x0000000000000003 ! rtpstreamdepay ! udpsink host=${HOST} port=${PORT2} \
    # udpsrc  port=${PORT3} buffer-size=${AUDIO_BUFFER_SIZE} ! queue ! rtpstreampay ! tcpclientsink host=${RELAY_HOST} port=${RELAY_PORT3} \
