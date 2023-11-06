#!/usr/bin/env python3

#!/usr/bin/env python3
import sys
import gi
import logging

gi.require_version("GLib", "2.0")
gi.require_version("GObject", "2.0")
gi.require_version("Gst", "1.0")

from gi.repository import Gst, GLib, GObject

HOST="127.0.0.1"
PORT=5000

logging.basicConfig(level=logging.DEBUG, format="[%(name)s] [%(levelname)8s] - %(message)s")
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

def main():
    # Initialize GStreamer
    Gst.init(sys.argv[1:])

    # # Create the elements
    # source = Gst.ElementFactory.make("videotestsrc", "source")
    # sink = Gst.ElementFactory.make("autovideosink", "sink")

    # # Create the empty pipeline
    # pipeline = Gst.Pipeline.new("test-pipeline")

    # if not pipeline or not source or not sink:
    #     logger.error("Not all elements could be created.")
    #     sys.exit(1)


    # # Build the pipeline
    # pipeline.add(source)
    # pipeline.add(sink)
    # if not source.link(sink):
    #     logger.error("Elements could not be linked.")
    #     sys.exit(1)

    # Modify the source's properties
    # source.props.pattern = 0
    # Can alternatively be done using `source.set_property("pattern",0)`
    # or using `Gst.util_set_object_arg(source, "pattern", 0)`

    # pipeline = Gst.parse_launch(
    #     f"tcpclientsrc name=tcpclientsrc host={HOST} port={PORT} do-timestamp=true ! application/x-rtp-stream,encoding-name=JPEG ! rtpstreamdepay ! rtpjpegdepay ! queue ! jpegdec ! queue ! textoverlay text='remote' ! autovideosink"
    #     )

    # if not pipeline:
    #     logger.error("No pipeline could be created.")
    #     sys.exit(1)

    # source = pipeline.get_by_name("tcpclientsrc")
    # if not source:
    #     logger.error("No source could be found.")
    #     sys.exit(1)

    # pad = source.get_static_pad("src")

    # # custom_timestamp = Gst.TIME_ARGS(Gst.CLOCK_TIME_NONE)  # Set your custom timestamp here

    # pad.add_probe(Gst.PadProbeType.BUFFER, pad_probe_cb)


    pipeline = Gst.Pipeline.new('pipeline')
    src = Gst.ElementFactory.make('tcpclientsrc', 'tcpclientsrc')
    src.set_property('host', HOST) # command center hostname
    src.set_property('port', PORT)     # command center port
    # src.set_property('do-timestamp', True)

    rtpjitterbuffer = Gst.ElementFactory.make('rtpjitterbuffer', 'rtpjitterbuffer')
    rtpjitterbuffer.set_property('latency', 50)

    cf = Gst.ElementFactory.make("capsfilter", None)
    caps = Gst.Caps.from_string("application/x-rtp-stream,encoding-name=JPEG")
    cf.set_property('caps', caps)
    rtpstreamdepay = Gst.ElementFactory.make('rtpstreamdepay', 'rtpstreamdepay')

    rtpjpegdepay = Gst.ElementFactory.make('rtpjpegdepay', 'rtpjpegdepay')
    queue0 = Gst.ElementFactory.make('queue', 'queue0')

    jpegdec = Gst.ElementFactory.make('jpegdec', 'jpegdec')
    queue1 = Gst.ElementFactory.make('queue', 'queue1')

    videorate = Gst.ElementFactory.make('videorate', 'videorate')

    cf1 = Gst.ElementFactory.make("capsfilter", None)
    caps1 = Gst.Caps.from_string("video/x-raw,framerate=30/1")
    cf1.set_property('caps', caps1)

    textoverlay = Gst.ElementFactory.make('textoverlay', 'textoverlay')
    textoverlay.set_property('text', 'remote')

    xvimagesink = Gst.ElementFactory.make('xvimagesink', 'xvimagesink')
    xvimagesink.set_property('async', False)

    if not pipeline or not src or not cf or not rtpstreamdepay:
        logger.error("Failed to create elements")
        return None

    # reference: https://stackoverflow.com/questions/49631176/typeerror-gst-bin-add-takes-exactly-2-arguments-5-given

    # elems = [src, cf, rtpstreamdepay, rtpjpegdepay, queue0, jpegdec, queue1, autovideosink]
    elems = [src,  cf, rtpstreamdepay, rtpjitterbuffer, rtpjpegdepay, queue0, jpegdec, queue1, videorate, cf1, textoverlay, xvimagesink]
    # elems = [cf, rtpstreamdepay, rtpjpegdepay, jpegdec, autovideosink]
    # pipeline.add(src)
    # pipeline.add(cf)
    # pipeline.add(rtpstreamdepay)
    # pipeline.add(sink)
    # pipeline.add(src)
    for elem in elems:
        pipeline.add(elem)

    # if not src.link(sink):
    #     logger.error("Failed to link elements for {}".format(name))
    #     return None
    for pair in pairwise(elems):
        if not pair[0].link(pair[1]):
            logger.error('Failed to link {} and {}'.format(pair[0], pair[1]))
            return None

    def probe_idle_cb(pad, info):
        logger.info("src_probe_cb")
        src.link(cf)
        return Gst.PadProbeReturn.REMOVE

    def probe_buffer_cb(pad, info):
        if info.type & Gst.PadProbeType.BUFFER:
            buffer = info.get_buffer()

            if buffer.pts != Gst.CLOCK_TIME_NONE:
                # PTS (Presentation Timestamp) is valid
                print(f"PTS: {buffer.pts}")
            else:
                # Handle GST_CLOCK_TIME_NONE, e.g., set a custom timestamp
                buffer.pts = Gst.SystemClock.obtain().get_internal_time()  # Set your custom timestamp here
                print(f"Custom Timestamp: {buffer.pts}")

        # buffer.pts = Gst.SystemClock.obtain().get_internal_time()  # Set your custom timestamp here
        return Gst.PadProbeReturn.OK


    # src_pad = src.get_static_pad('src')
    # src_pad.add_probe(Gst.PadProbeType.IDLE, probe_idle_cb)

    # sink_pad = videorate.get_static_pad('sink')
    # sink_pad.add_probe(Gst.PadProbeType.BUFFER, probe_buffer_cb)

    # Start playing
    ret = pipeline.set_state(Gst.State.PLAYING)
    if ret == Gst.StateChangeReturn.FAILURE:
        logger.error("Unable to set the pipeline to the playing state.")
        sys.exit(1)

    # # Get the pipeline's clock
    # pipeline_clock = pipeline.get_clock()

    # if not pipeline_clock:
    #     print("Pipeline clock is not available.")
    #     return

    # Create a new clock with the desired clock type (e.g., GST_CLOCK_TYPE_REALTIME)
    print(type(Gst.SystemClock.clock))
    print(Gst.SystemClock.clock)
    # sys.exit(0)
    # utc_clock = Gst.SystemClock.obtain_realtime()

    # Set the pipeline's clock to the UTC clock
    # pipeline.set_clock(utc_clock)

    gst_loop = GLib.MainLoop()

    # Wait for EOS or error
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