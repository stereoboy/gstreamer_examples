#!/bin/sh

HOST=192.168.0.4

v4l2-ctl --list-devices

xterm +hold -title video0 -e \
  gst-launch-1.0 -v v4l2src device=/dev/video0 ! "image/jpeg, width=(int)640, height=(int)480, pixel-aspect-ratio=(fraction)1/1, framerate=(fraction)30/1" ! rtpjpegpay !\
  udpsink host=$HOST port=8553 &

xterm +hold -title video1 -e \
  gst-launch-1.0 -v v4l2src device=/dev/video1 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay !\
  udpsink host=$HOST port=8554 &

xterm +hold -title video2 -e \
  gst-launch-1.0 -v v4l2src device=/dev/video2 !image/jpeg, width=640, height=480, pixel-aspect-ratio=1/1, framerate=30/1 ! rtpjpegpay !\
  udpsink host=$HOST port=8555 &

xterm +hold -title audio -e \
  gst-launch-1.0 -v pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo !\
  alawenc ! rtpgstpay !\
  udpsink host=$HOST port=8556 &

