#!/bin/sh

set -x

WIDTH=640
HEIGHT=480

DEVICE=/dev/video2

gst-launch-1.0 -tv v4l2src device=${DEVICE}  ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=30/1 !  jpegdec ! fpsdisplaysink video-sink="autovideosink" sync=false
