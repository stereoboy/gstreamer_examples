#!/bin/sh

set -x

gst-launch-1.0 -tv v4l2src device=/dev/video0  ! image/jpeg, width=1920, height=1080, pixel-aspect-ratio=1/1, framerate=30/1 !  jpegdec ! autovideosink
