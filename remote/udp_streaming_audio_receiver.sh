#!/bin/sh

set -x

echo "target is $@"

case $@ in
    0)
        echo "Alaw codec clock-rate=8000"
        # working, little slow
        gst-launch-1.0 -v udpsrc port=8555 !application/x-rtp, media=audio, payload=8, clock-rate=8000 !\
            rtppcmadepay ! alawdec ! autoaudiosink ;;
    1)
        echo "Alaw codec clock-rate=90000"
        # working, high-quality, little slow
        gst-launch-1.0 -v udpsrc port=8555 ! 'application/x-rtp, media=application, clock-rate=90000, encoding-name=X-GST, caps="YXVkaW8veC1hbGF3LCByYXRlPShpbnQpNDQxMDAsIGNoYW5uZWxzPShpbnQpMg\=\=", capsversion=0' ! \
            rtpgstdepay ! alawdec ! autoaudiosink ;;
    2)
        echo "Raw Audio L8"
        # working, very noisy, little slow
        gst-launch-1.0 udpsrc port=8555 !application/x-rtp, media=audio, encoding-name=L8, payload=96, clock-rate=44100, channels=2, channel-mask=0x0000000000000003 !\
             rtpL8depay ! autoaudiosink ;;

    3)
        echo "Raw Audio L16"
        # working, little slow
        gst-launch-1.0 -v udpsrc port=8555 !application/x-rtp, media=audio, clock-rate=44100, encoding-name=L16, channels=2, channel-mask=0x0000000000000003 !\
              rtpL16depay ! autoaudiosink ;;

    4)
        echo "A3C codec"
        # working, slow
        gst-launch-1.0 -v udpsrc port=8555 ! application/x-rtp, media=audio, clock-rate=44100, encoding-name=AC3 !\
              rtpac3depay ! a52dec ! pulsesink ;;

    5)
        echo "AAC codec"
        # references https://marc.info/?l=gstreamer-devel&m=150650921723890&w=2
        # working, slow
        gst-launch-1.0 -v udpsrc port=8555 !application/x-rtp, media=audio, clock-rate=44100, encoding-name=MP4A-LATM, config=40002410adca00 ! rtpjitterbuffer !\
          rtpmp4adepay !  avdec_aac ! audioconvert ! autoaudiosink;;

esac


#################################################################################################
#gst-launch-1.0 -v udpsrc port=8555 !application/x-rtp, media=audio, payload=96, clock-rate=90000, encoding-name=MPA !\
#  rtpmpadepay !  avdec_mp3 ! audioconvert ! autoaudiosink
#################################################################################################
#gst-launch-1.0 udpsrc port=8555 !application/x-rtp, media=audio, payload=96, clock-rate=8000 !\
#  rtppcmadepay ! autoaudiosink
