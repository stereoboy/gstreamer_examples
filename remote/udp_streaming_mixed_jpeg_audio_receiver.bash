#!/bin/bash

set -x

PORT0=5000
PORT1=5001
PORT2=5002
PORT3=5003

WIDTH=1280
HEIGHT=720

AUDIO_BUFFER_SIZE=100000

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

#
# to remove "WARN            rtpjpegdepay gstrtpjpegdepay.c:758:gst_rtp_jpeg_depay_process:<rtpjpegdepay0> discarding data packets received when we have no header"
# references
#   - https://gstreamer-devel.narkive.com/nud8O26p/possible-bug-in-rtpjpegpay-and-or-rtpjpegdepay
#
gst-launch-1.0 -tv \
    udpsrc port=${PORT0} buffer-size=$((${WIDTH}*${HEIGHT}*3)) caps=application/x-rtp,media=video,encoding-name=JPEG ! rtpjpegdepay !  queue ! jpegparse ! jpegdec ! textoverlay text="remote left" ! autovideosink \
    udpsrc port=${PORT1} buffer-size=$((${WIDTH}*${HEIGHT}*3)) caps=application/x-rtp,media=video,encoding-name=JPEG ! rtpjpegdepay !  queue ! jpegparse ! jpegdec ! textoverlay text="remote right" ! autovideosink \
    udpsrc port=${PORT2} buffer-size=${AUDIO_BUFFER_SIZE} ! application/x-rtp, media=audio, clock-rate=44100, encoding-name=L16, channels=2, channel-mask=0x0000000000000003 ! rtpL16depay ! pulsesink volume=2.0 device=alsa_output.usb-$audio_dev_id_serial-00.analog-stereo