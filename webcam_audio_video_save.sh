#!/bin/sh

#
# references
# - https://stackoverflow.com/questions/47593677/capture-segmented-audio-and-video-with-gstreamer
# - https://stackoverflow.com/questions/35744114/getting-warning-messages-from-alsasrc
# - https://stackoverflow.com/questions/36703373/capturing-both-audio-and-video-with-gstreamer-to-a-file
# - https://stackoverflow.com/questions/21152303/how-to-use-gstreamer-to-save-webcam-video-to-file
# - https://stackoverflow.com/questions/68243539/gstreamer-rtpdepay-error-segment-with-non-time-format-not-supported
# - https://stackoverflow.com/questions/49270207/how-to-record-audio-and-video-in-gstreamer


#gst-launch-1.0 -e v4l2src device=/dev/video0 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=60/1 ! videoconvert ! queue ! x264enc tune=zerolatency ! mux. \
#  pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo ! queue ! audioconvert ! audioresample ! voaacenc ! aacparse ! qtmux name=mux ! filesink location=test.mp4 sync=false


#gst-launch-1.0 -v -e autovideosrc ! queue ! x264enc ! 'video/x-h264,stream-format=(string)byte-stream' ! h264parse ! queue ! mux. \
#  autoaudiosrc ! qtmux name=mux ! filesink sync=false location=test.mp4

#gst-launch-1.0 -v -e autovideosrc ! queue ! x264enc ! 'video/x-h264,stream-format=(string)byte-stream' ! h264parse ! queue ! mux. \
#  autoaudiosrc ! decodebin ! audioconvert ! queue ! avimux name=mux ! filesink sync=false location=test.mp4

#gst-launch-1.0 -v -e avimux name=mux ! filesink location=test.mp4 sync=false\
#  v4l2src device=/dev/video0 ! video/x-raw, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 !\
#  videoconvert ! x264enc ! 'video/x-h264,stream-format=(string)byte-stream' ! h264parse ! queue ! mux.video_0 \
#  autoaudiosrc ! decodebin ! audioconvert ! queue ! mux.audio_0

#gst-launch-1.0 -v -e autoaudiosrc ! decodebin ! audioconvert ! queue ! avimux name=mux ! filesink sync=false location=test.mp4

gst-launch-1.0 -v -e avimux name=mux ! filesink location=test.mp4 sync=false\
  v4l2src device=/dev/video0 ! image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=60/1 !\
  queue ! mux.video_0 \
  pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo ! alawenc ! queue ! mux.audio_0
