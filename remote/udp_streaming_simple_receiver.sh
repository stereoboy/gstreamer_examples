gst-launch-1.0 udpsrc port=8554 caps=application/x-rtp,encoding-name=JPEG,payload=26 ! rtpjpegdepay ! jpegdec ! autovideosink
