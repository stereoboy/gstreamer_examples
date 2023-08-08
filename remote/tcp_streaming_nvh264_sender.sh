#!/bin/sh

set -x

HOST=127.0.0.1

gst-launch-1.0 -tv v4l2src device=/dev/video0  ! image/jpeg, width=1280, height=720, pixel-aspect-ratio=1/1, framerate=30/1 ! jpegdec ! timeoverlay ! tee name=t \
    t. ! queue ! nvvidconv flip-method=0 ! "video/x-raw(memory:NVMM)" ! nvv4l2h264enc maxperf-enable=1 insert-sps-pps=1 idrinterval=256 bitrate=6000000 MeasureEncoderLatency=true ! tcpserversink host=$HOST port=5000 \
    t. ! queue ! textoverlay text="local" ! autovideosink


#gst-launch-1.0 -tv v4l2src device=/dev/video0  ! video/x-raw, width=1280, height=720, pixel-aspect-ratio=1/1, framerate=30/1 !  nvvidconv flip-method=0 ! nvv4l2h264enc insert-sps-pps=true bitrate=16000000 ! tcpserversink host=$HOST port=5000 \

