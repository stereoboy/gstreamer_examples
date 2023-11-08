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
DEFAULT_SENDER_HOST="127.0.0.1"
DEFAULT_PORT=5000
DEFAULT_RELAY_PORT=5004

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


def build_video_pipeline(hostname, port, relay_port,  sender_hostname):

    WIDTH=1280
    HEIGHT=720
    launch_str = f" udpsrc  port={port}     buffer-size={WIDTH*HEIGHT*3} ! queue ! rtpstreampay ! tcpserversink host={hostname} port={relay_port} \
                    udpsrc  port={port + 1} buffer-size={WIDTH*HEIGHT*3} ! queue ! rtpstreampay ! tcpserversink host={hostname} port={relay_port + 1} "
    stereo_video_pipeline = Gst.parse_launch(launch_str)

    logger.info(launch_str)

    return stereo_video_pipeline

def build_audio_in_pipeline(hostname, port, relay_port, sender_hostname):
    AUDIO_BUFFER_SIZE=100000

    audio_pipeline = Gst.parse_launch(
        f" udpsrc  port={port} buffer-size={AUDIO_BUFFER_SIZE} ! queue ! rtpstreampay ! tcpserversink host={hostname} port={relay_port} ")

    return audio_pipeline

def build_audio_out_pipeline(hostname, port, relay_port, sender_hostname):
    audio_pipeline = Gst.parse_launch(
        f"tcpserversrc host={hostname} port={relay_port} ! application/x-rtp-stream,media=audio, clock-rate=44100, encoding-name=L16, channels=2, channel-mask=0x0000000000000003 ! rtpstreamdepay ! udpsink host={sender_hostname} port={port}")

    return audio_pipeline

def main():
    parser = argparse.ArgumentParser(description='Prototype for Sending Audio/JPEG Streaming')
    parser.add_argument('-H', '--hostname', action='store', dest='hostname', default=DEFAULT_HOST, help='relay server hostname or ip address')
    parser.add_argument('-p', '--port', action='store', dest='port', type=int, default=DEFAULT_PORT, help='base port number for streaming to listen on')
    parser.add_argument('-r', '--relay-port', action='store', dest='relay_port', type=int, default=DEFAULT_RELAY_PORT, help='base port number for streaming to listen on')
    parser.add_argument('-S', '--sender-hostname', action='store', dest='sender_hostname', default=DEFAULT_SENDER_HOST, help='sender hostname or ip address')

    options = parser.parse_args(sys.argv[1:])

    logger.info(options)

    # Initialize GStreamer
    Gst.init(None)

    stereo_video_pipeline = build_video_pipeline(options.hostname, options.port, options.relay_port, options.sender_hostname)

    audio_in_pipeline = build_audio_in_pipeline(options.hostname, options.port + 2, options.relay_port + 2, options.sender_hostname)
    audio_out_pipeline = build_audio_out_pipeline(options.hostname, options.port + 3, options.relay_port + 3, options.sender_hostname)


    pipelines = [stereo_video_pipeline, audio_in_pipeline, audio_out_pipeline]
    # pipelines = [stereo_video_pipeline, audio_in_pipeline]
    # pipelines = [stereo_video_pipeline]

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