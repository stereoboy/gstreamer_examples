#!/bin/sh

set -x

PORT=5000

WIDTH=1280
HEIGHT=720

#
# to remove "WARN            rtpjpegdepay gstrtpjpegdepay.c:758:gst_rtp_jpeg_depay_process:<rtpjpegdepay0> discarding data packets received when we have no header"
# references
#   - https://gstreamer-devel.narkive.com/nud8O26p/possible-bug-in-rtpjpegpay-and-or-rtpjpegdepay
#
gst-launch-1.0 -tv \
     udpsrc port=${PORT} buffer-size=$((${WIDTH}*${HEIGHT}*3*2)) caps=application/x-rtp,media=video,encoding-name=JPEG ! rtpjpegdepay !  queue ! jpegparse ! jpegdec ! \
     textoverlay text="remote" !  fpsdisplaysink video-sink="autovideosink" \


#gst-launch-1.0 -tv \
#    udpsrc port=${PORT} buffer-size=$((${WIDTH}*${HEIGHT}*3*2)) caps=application/x-rtp,media=video,encoding-name=JPEG ! rtpjpegdepay !  queue ! jpegparse ! jpegdec ! tee name=t \
#    t. ! queue ! videobox bottom=${HEIGHT} ! textoverlay text="remote left" !  fpsdisplaysink video-sink="autovideosink" \
#    t. ! queue ! videobox top=${HEIGHT}    ! textoverlay text="remote right" !  fpsdisplaysink video-sink="autovideosink" \
