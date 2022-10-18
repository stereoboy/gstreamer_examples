#!/bin/sh

HOST=192.168.0.4

set -x

echo "target is $@"

DEVICE=alsa_input.usb-Creative_Technology_Ltd_Sound_BlasterX_G1_00141088-00.analog-stereo
case $@ in

    0)
        echo "Alaw codec clock-rate=8000"
        # working, low-quality, little slow
        gst-launch-1.0 -v pulsesrc device=$DEVICE actual-buffer-time=20000 !\
          alawenc ! rtppcmapay !application/x-rtp, payload=8, clock-rate=8000 !\
          udpsink host=$HOST port=8555
        ;;
    1)
        echo "Alaw codec clock-rate=900000"
        # working, high-quality, little slow
        gst-launch-1.0 -v pulsesrc device=$DEVICE !\
          alawenc ! rtpgstpay !\
          udpsink host=$HOST port=8555

        ;;
    2)
        echo "Raw Audio L8"
        # working, noisy, little slow
        gst-launch-1.0 -v pulsesrc device=$DEVICE !\
          rtpL8pay ! \
          udpsink host=$HOST port=8555
        ;;
    3)
        echo "Raw Audio L16"
        # working, little slow
        gst-launch-1.0 -v pulsesrc device=$DEVICE !\
          rtpL16pay !\
          udpsink host=$HOST port=8555
        ;;
    4)
        echo "A3C codec"
        # work, slow
        gst-launch-1.0 -v pulsesrc device=$DEVICE !\
          avenc_ac3 ! rtpac3pay ! \
          udpsink host=$HOST port=8555
        ;;

    5)
        echo "AAC codec"
        #########################################################################
        #
        # references https://marc.info/?l=gstreamer-devel&m=150650921723890&w=2
        # work, slow
        gst-launch-1.0 -v pulsesrc device=$DEVICE !\
          avenc_aac ! rtpmp4apay ! \
          udpsink host=$HOST port=8555

        #gst-launch-1.0 -v audiotestsrc ! audioconvert ! avenc_aac ! rtpmp4apay ! \
        #  udpsink host=127.0.0.1 port=8555

        #gst-launch-1.0 -v pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo !\
        #  avenc_aac ! avdec_aac! \
        #  autoaudiosink
        #########################################################################
        ;;

esac






#########################################################################
#gst-launch-1.0 -v pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo !\
#  avenc_mp3 ! rtpmpapay ! \
#  udpsink host=127.0.0.1 port=8555
#########################################################################

#gst-launch-1.0 -v pulsesrc device=alsa_input.usb-046d_Logitech_StreamCam_6A86D645-02.analog-stereo !\
#  audio/x-raw, format=S16LE, rate=8000 ! \
#  alawenc ! rtppcmapay !application/x-rtp, media=audio, payload=96, clock-rate=90000, encoding-name=PCMA !\
#  udpsink host=127.0.0.1 port=8555

#  alawenc ! rtppcmapay !application/x-rtp, payload=8, clock-rate=8000 !\
