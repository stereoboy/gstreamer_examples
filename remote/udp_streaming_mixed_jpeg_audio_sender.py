#!/usr/bin/env python3
import sys
import gi
import logging
import argparse

gi.require_version("GLib", "2.0")
gi.require_version("GObject", "2.0")
gi.require_version("Gst", "1.0")

from gi.repository import Gst, GLib, GObject

DEFAULT_HOST="127.0.0.1"
DEFAULT_PORT=5000

logging.basicConfig(level=logging.DEBUG, format="[%(name)s] [%(levelname)8s] %(message)s")
logger = logging.getLogger(__name__)

def message_handler(bus, message, pipeline, loop):
    logger.info("{}".format(message))
    t = message.type
    # scenario = message.scenario
    # pipeline = Gst.validate_scenario_get_pipeline(scenario)

    if t == Gst.MessageType.EOS:
        logger.info("Pipeline {} got End-of-stream".format(
            message.src.get_name()))
        loop.quit()
    elif t == Gst.MessageType.ERROR:
        err, debug = message.parse_error()
        logger.error("%s: (%s) %s\n" % (message.src.get_name(), err, debug))
        loop.quit()
    elif t == Gst.MessageType.STATE_CHANGED:
        old_state, new_state, pending_state = message.parse_state_changed()
        logger.info("Pipeline {} state changed from {} to {}".format(
                        message.src.get_name(), Gst.Element.state_get_name(old_state),
                        Gst.Element.state_get_name(new_state)))
    elif t == Gst.MessageType.NEW_CLOCK:
        logger.info("{}: New CLOCK".format(message.src.get_name()))
    elif t == Gst.MessageType.TAG:
        logger.info("{}: TAG".format(message.src.get_name()))
    elif t == Gst.MessageType.TOC:
        logger.info("{}: TOC".format(message.src.get_name()))
    elif t == Gst.MessageType.BUFFERING:
        logger.info("{}: BUFFERING".format(message.src.get_name()))
    elif t == Gst.MessageType.LATENCY:
        logger.info("{}: LATENCY".format(message.src.get_name()))
        # Gst.Bin.recalculate_latency(pipeline)
        structure = message.get_structure()
        if structure is not None:
            logger.info("{}:".format(structure.to_string()))
    elif t == Gst.MessageType.PROGRESS:
        logger.info("{}: PROGRESS".format(message.src.get_name()))
    elif t == Gst.MessageType.ELEMENT:
        logger.info("{}: ELEMENT {}".format(message.src.get_name(), message))
        structure = message.get_structure()
        logger.info("{}:".format(structure.to_string()))
    elif t == Gst.MessageType.QOS:
        logger.info("{}: ELEMENT {}".format(message.src.get_name(), message))
        structure = message.get_structure()
        logger.info("{}:".format(structure.to_string()))
    else:
        logger.info("{}: {}".format(message.src.get_name(), t))


import itertools
def pairwise(iterable):
    a, b = itertools.tee(iterable)
    next(b, None)
    return zip(a, b)

def build_bin(name, elems):
    bin = Gst.Bin.new(name)
    for elem in elems:
        bin.add(elem)
    for pair in pairwise(elems):
        if not pair[0].link(pair[1]):
            logger.error('Failed to link {} and {}'.format(pair[0], pair[1]))
            return None

    return bin


def build_video_pipeline(hostname, port):

    DEVICE0='/dev/video0'
    DEVICE1='/dev/video2'
    WIDTH=1280
    HEIGHT=720
    FRAMERATE='30/1'

    stereo_video_pipeline = Gst.parse_launch(
        f"v4l2src device={DEVICE0} ! image/jpeg, width={WIDTH}, height={HEIGHT}, pixel-aspect-ratio=1/1, framerate={FRAMERATE} ! jpegdec ! timeoverlay ! tee name=t0 \
        t0. ! queue ! jpegenc ! rtpjpegpay ! udpsink host={hostname} port={port} \
        t0. ! queue ! textoverlay text='local left' ! autovideosink \
        v4l2src device={DEVICE1} ! image/jpeg, width={WIDTH}, height={HEIGHT}, pixel-aspect-ratio=1/1, framerate={FRAMERATE} ! jpegdec ! timeoverlay ! tee name=t1 \
        t1. ! queue ! jpegenc ! rtpjpegpay ! udpsink host={hostname} port={port + 1} \
        t1. ! queue ! textoverlay text='local right' ! autovideosink"
        )

    return stereo_video_pipeline

def build_audio_in_pipeline(hostname, port):
    #
    # reference: https://github.com/GStreamer/gstreamer/blob/63bb0b8de7fb7c206b2d9a598226df401f3863e0/subprojects/gst-python/examples/record_sound.py
    #
    monitor = Gst.DeviceMonitor.new()
    monitor.add_filter("Audio/Source", None)
    monitor.start()

    def print_key_value(id, value):
        #
        # reference: https://lazka.github.io/pgi-docs/GLib-2.0/functions.html#GLib.quark_to_string
        #
        name = GLib.quark_to_string(id)
        logger.info("  - {}: {}".format(name, value))
        return True

    # This is happening synchonously, use the GstBus based API and
    # monitor.start() to avoid blocking the main thread.
    devices = monitor.get_devices()

    for i, d in enumerate(devices):
        logger.info("[%d] %s" % (i, d.get_display_name()))
        d.get_properties().foreach(print_key_value)

    if not devices:
        logger.info("No microphone found...")
        sys.exit(1)

    default = [d for d in devices if d.get_properties().get_value("device.description") == "Sound BlasterX G1 Analog Stereo"]

    if len(default) == 1:
        device = default[0]
        logger.info("%s(%s)" % (device.get_display_name(), device.get_device_class()))
    else:
        logger.info("Available microphones:")
        for i, d in enumerate(devices):
            logger.info("%d - %s" % (i, d.get_display_name()))
        res = int(input("Select device: "))
        device = devices[res]

    logger.info("{}".format("{} is selected".format(device.get_display_name())))

    monitor.stop()

    audio_pipeline = Gst.Pipeline.new('pipeline')

    audio_source = device.create_element()
    audio_source.set_property('volume', 2.0)

    audio_convert0 = Gst.ElementFactory.make('audioconvert')

    audiochebband = Gst.ElementFactory.make('audiochebband')
    audiochebband.set_property('mode', 'band-pass')
    audiochebband.set_property('lower-frequency', 500)
    audiochebband.set_property('upper-frequency', 5000)

    audio_convert1 = Gst.ElementFactory.make('audioconvert')

    rtpL16pay = Gst.ElementFactory.make('rtpL16pay')

    audio_udpsink = Gst.ElementFactory.make('udpsink')
    audio_udpsink.set_property('host', hostname)
    audio_udpsink.set_property('port', port)

    elems = [audio_source, audio_convert0, audiochebband, audio_convert1,  rtpL16pay, audio_udpsink]

    for elem in elems:
        audio_pipeline.add(elem)

    for pair in pairwise(elems):
        if not pair[0].link(pair[1]):
            logger.error('Failed to link {} and {}'.format(pair[0], pair[1]))
            return None

    return audio_pipeline

def build_audio_out_pipeline(port):
    #
    # reference: https://github.com/GStreamer/gstreamer/blob/63bb0b8de7fb7c206b2d9a598226df401f3863e0/subprojects/gst-python/examples/record_sound.py
    #
    monitor = Gst.DeviceMonitor.new()
    monitor.add_filter("Audio/Sink", None)
    monitor.start()

    def print_key_value(id, value):
        #
        # reference: https://lazka.github.io/pgi-docs/GLib-2.0/functions.html#GLib.quark_to_string
        #
        name = GLib.quark_to_string(id)
        logger.info("  - {}: {}".format(name, value))
        return True

    # This is happening synchonously, use the GstBus based API and
    # monitor.start() to avoid blocking the main thread.
    devices = monitor.get_devices()

    for i, d in enumerate(devices):
        logger.info("[%d] %s" % (i, d.get_display_name()))
        d.get_properties().foreach(print_key_value)

    if not devices:
        logger.info("No speaker found...")
        sys.exit(1)

    default = [d for d in devices if d.get_properties().get_value("device.description") == "Sound BlasterX G1 Analog Stereo"]

    if len(default) == 1:
        device = default[0]
        logger.info("%s(%s)" % (device.get_display_name(), device.get_device_class()))
    else:
        logger.info("Available microphones:")
        for i, d in enumerate(devices):
            logger.info("%d - %s" % (i, d.get_display_name()))
        res = int(input("Select device: "))
        device = devices[res]

    logger.info("{}".format("{} is selected".format(device.get_display_name())))

    monitor.stop()

    audio_pipeline = Gst.Pipeline.new('pipeline')


    audio_udpsrc = Gst.ElementFactory.make('udpsrc')
    audio_udpsrc.set_property('port', port)

    cf = Gst.ElementFactory.make("capsfilter", None)
    caps = Gst.Caps.from_string("application/x-rtp, media=audio, clock-rate=44100, encoding-name=L16, channels=2, channel-mask=0x0000000000000003")
    cf.set_property('caps', caps)

    rtpL16depay = Gst.ElementFactory.make('rtpL16depay')

    audio_sink = device.create_element()
    audio_sink.set_property('volume', 2.0)

    elems = [audio_udpsrc, cf, rtpL16depay, audio_sink]

    for elem in elems:
        audio_pipeline.add(elem)

    for pair in pairwise(elems):
        if not pair[0].link(pair[1]):
            logger.error('Failed to link {} and {}'.format(pair[0], pair[1]))
            return None

    return audio_pipeline

def main():
    parser = argparse.ArgumentParser(description='Prototype for Sending Audio/JPEG Streaming')
    parser.add_argument('-H', '--hostname', action='store', dest='hostname', default=DEFAULT_HOST, help='receiver\'s hostname or ip address')
    parser.add_argument('-p', '--port', action='store', dest='port', type=int, default=DEFAULT_PORT, help='starting port number for streaming')

    options = parser.parse_args(sys.argv[1:])

    logger.info(options)

    # Initialize GStreamer
    Gst.init(None)

    stereo_video_pipeline = build_video_pipeline(options.hostname, options.port)

    audio_in_pipeline = build_audio_in_pipeline(options.hostname, options.port + 2)
    audio_out_pipeline = build_audio_out_pipeline(options.port + 3)


    pipelines = [stereo_video_pipeline, audio_in_pipeline, audio_out_pipeline]

    for pipeline in pipelines:
        if not pipeline:
            logger.error("No pipeline could be created.")
            sys.exit(1)

    # Start playing
    for pipeline in pipelines:
        ret = pipeline.set_state(Gst.State.PLAYING)
        if ret == Gst.StateChangeReturn.FAILURE:
            logger.error("Unable to set the pipeline to the playing state.")
            sys.exit(1)

    gst_loop = GLib.MainLoop()

    # Wait for EOS or error
    for pipeline in pipelines:
        bus = pipeline.get_bus()
        bus.add_signal_watch()
        bus.connect("message", message_handler, pipeline, gst_loop)

    try:
        gst_loop.run()
    except KeyboardInterrupt as e:
        logger.info("Stopping GStreamer pipeline")

    pipeline.set_state(Gst.State.NULL)

if __name__ == "__main__":
    main()