#!/bin/bash

set -x

#HOST=54.193.231.0 # US server
HOST=127.0.0.1
PORT0=5000
PORT1=5001
PORT2=5002
PORT3=5003

DEVICE0=/dev/video0
DEVICE1=/dev/video2
WIDTH=1280
HEIGHT=720
FRAMERATE=30/1

function log_info() {
    echo "[NESFR VR (@TAG@) BootUp] $*"
}

function log_error() {
    echo "[NESFR VR (@TAG@) BootUp] ERR $*" >&2
}

function init_audio() {
    # Get the list of sound card devices
    devices=$(ls /dev/snd/controlC*)

    # Iterate through each device
    for device in $devices; do
        log_info "-------------------------"
        log_info "Device: $device"

        # Use udevadm to get detailed information
        info=$(udevadm info --query=all --name=$device)

        # Extract and print relevant information
        model=$(echo "$info" | grep "ID_MODEL=" | cut -d "=" -f 2)
        vendor=$(echo "$info" | grep "ID_VENDOR=" | cut -d "=" -f 2)
        audio_dev_id_serial=$(echo "$info" | grep "ID_SERIAL=" | cut -d "=" -f 2)
        log_info "Model: $model"
        log_info "Vendor: $vendor"
        # TODO: audio setup is hard coded
        if [ "$model" = "Sound_BlasterX_G1" ] && [ "$vendor" = "Creative_Technology_Ltd"  ]; then
            break
        fi
    done
    log_info "Id Serial: $audio_dev_id_serial"

    if [ -z "$audio_dev_id_serial" ]; then
        return 1
    fi

    # No daemonized pulseaudio to kill after preprocess
    pulseaudio --verbose  --exit-idle-time=-1 --daemonize=no --disallow-exit --log-target=journal &
    PULSEAUDIO_PID=$!
    log_info "PULSEAUDIO_PID=$PULSEAUDIO_PID"

    return 0
}

init_audio

gst-launch-1.0 -tv \
    v4l2src device=${DEVICE0} ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=${FRAMERATE} ! jpegdec ! timeoverlay ! tee name=t0 \
    t0. ! queue ! jpegenc ! rtpjpegpay ! udpsink host=${HOST} port=${PORT0} \
    t0. ! queue ! textoverlay text="local left" ! autovideosink \
    v4l2src device=${DEVICE1} ! image/jpeg, width=${WIDTH}, height=${HEIGHT}, pixel-aspect-ratio=1/1, framerate=${FRAMERATE} ! jpegdec ! timeoverlay ! tee name=t1 \
    t1. ! queue ! jpegenc ! rtpjpegpay ! udpsink host=${HOST} port=${PORT1} \
    t1. ! queue ! textoverlay text="local right" ! autovideosink \
    pulsesrc volume=2.0 device=alsa_input.usb-$audio_dev_id_serial-00.analog-stereo ! audioconvert ! audiochebband mode=band-pass lower-frequency=500 upper-frequency=5000 ! audioconvert ! rtpL16pay ! udpsink host=${HOST} port=${PORT2} \
