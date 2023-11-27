#!/bin/bash

#
# references
#  - https://gstreamer.freedesktop.org/documentation/opengl/glstereomix.html?gi-language=c
#

set -x
#WIDTH=1920
#HEIGHT=1080
WIDTH=640
HEIGHT=480
MULTI_VIEW_MODE=side-by-side
#MULTI_VIEW_MODE=top-bottom

#gst-launch-1.0 -ev v4l2src device=/dev/video0 name=left \
#     v4l2src device=/dev/video2 name=right glstereomix name=mix \
#     left.  ! image/jpeg,width=${WIDTH},height=${HEIGHT} ! jpegdec ! videoconvert ! video/x-raw,format=RGBA ! glupload ! mix.  \
#     right. ! image/jpeg,width=${WIDTH},height=${HEIGHT} ! jpegdec ! videoconvert ! video/x-raw,format=RGBA ! glupload ! mix.  \
#     mix. ! video/x-raw'(memory:GLMemory)',multiview-mode=${MULTI_VIEW_MODE} ! \
#     queue ! progressreport ! glimagesink output-multiview-mode=${MULTI_VIEW_MODE}

 gst-launch-1.0 -v videotestsrc pattern=ball name=left \
     videotestsrc name=right glstereomix name=mix \
     left. ! video/x-raw,width=${WIDTH},height=${HEIGHT}! glupload ! mix.  \
     right. ! video/x-raw,width=${WIDTH},height=${HEIGHT}! glupload ! mix.  \
     mix. ! video/x-raw'(memory:GLMemory)',multiview-mode=side-by-side ! \
     queue ! glimagesink output-multiview-mode=side-by-side

# gst-launch-1.0 -ev v4l2src name=left \
#     videotestsrc name=right \
#     glstereomix name=mix \
#     left. ! image/jpeg,width=640,height=480 ! jpegdec ! videoconvert ! video/x-raw,width=640,height=480 ! glupload ! glcolorconvert ! mix.  \
#     right. ! video/x-raw,width=640,height=480 ! glupload ! mix.  \
#     mix. ! video/x-raw'(memory:GLMemory)',multiview-mode=top-bottom ! \
#     glcolorconvert ! queue ! glimagesink output-multiview-mode=side-by-side
