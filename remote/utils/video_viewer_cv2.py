#!/usr/bin/env python3
'''
    python3 video_viewer.py
'''

#
# reference:
#  - https://lifestyletransfer.com/how-to-use-gstreamer-appsink-in-python/
#  - https://stackoverflow.com/questions/58763496/receive-numpy-array-realtime-from-gstreamer/58806157#58806157
#
#

import sys
import time
import argparse
import logging
import numpy as np
import cv2
import threading

import gi
gi.require_version('Gst', '1.0')
gi.require_version('GstApp', '1.0')
from gi.repository import Gst, GObject, GstApp, GLib

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - [%(threadName)s] %(funcName)s:%(lineno)d - %(message)s')


# Define a callback function to be called when a new frame is available
def print_key_value(id, value):
    #
    # reference: https://lazka.github.io/pgi-docs/GLib-2.0/functions.html#GLib.quark_to_string
    #
    name = GLib.quark_to_string(id)
    print("  - {}: {}".format(name, value))
    return True

DEFAULT_VIDEO_ROWS=1
DEFAULT_VIDEO_COLS=2

ID_LEFT=0
ID_RIGHT=1
FIXED_HEIGHT=480
TARGET_DRAW_INTERVAL=round(1000/30)

class Viewer(object):
    def __init__(self, rows=DEFAULT_VIDEO_ROWS, cols=DEFAULT_VIDEO_COLS):
        self.rows = rows
        self.cols = cols

        self.width = 1920
        self.height = 1080

        self.vis_width = int(FIXED_HEIGHT* self.width/self.height)
        self.vis_height = int(FIXED_HEIGHT)

        self.frames = [None, None]

        self.mutex = threading.Lock()

    def new_sample_cb(self, appsink, row, col):
        # with self.mutex:

        # logging.info("col={}".format(col))
        sample = appsink.emit("pull-sample")
        buffer = sample.get_buffer()
        caps = sample.get_caps()

        # print("caps.get_size() = {}".format(caps.get_size()))
        # # Extract the width and height info from the sample's caps
        # for i in range(caps.get_size()):
        #     print("[{}]".format(i))
        #     caps.get_structure(i).foreach(print_key_value)

        width = caps.get_structure(0).get_value("width")
        height = caps.get_structure(0).get_value("height")

        # logging.info("{}x{}".format(width, height))

        # Map the buffer to read its data
        success, map_info = buffer.map(Gst.MapFlags.READ)
        if success:
            self.frames[col] = np.ndarray(shape=(height, width, 3), dtype=np.uint8, buffer=map_info.data)
            buffer.unmap(map_info)
            # Display the frame using OpenCV (you can replace this with your own processing)
            # self.img[col].set_data(data)
        # self.axes[row].imshow(data)
        # self.fig.canvas.draw()
        return Gst.FlowReturn.OK

    def run(self):
        # Initialize GStreamer
        Gst.init(None)

        # GStreamer pipeline definition
        # pipeline_string = f"v4l2src device=/dev/video0 ! image/jpeg,width={self.width},height={self.height} ! jpegdec ! videoconvert  ! video/x-raw,format=(string)RGB ! tee name=t0 \
        #     t0. ! queue ! appsink name=sink_left \
        #     t0. ! queue ! videoconvert ! autovideosink "
        pipeline_string = f"v4l2src device=/dev/video0 ! image/jpeg,width={self.width},height={self.height} ! jpegdec ! videoconvert ! textoverlay text=left ! video/x-raw,format=(string)RGB ! appsink name=sink_left "

        # Create a GStreamer pipeline
        pipeline = Gst.parse_launch(pipeline_string)

        # Get the appsink element
        sink = pipeline.get_by_name("sink_left")
        if not sink:
            logging.error("no appsink element with name of 'sink_left'")

        # caps = Gst.Caps.from_string("video/x-raw,format=(string)RGB")
        # # Set caps on the appsink to ensure the correct format
        # sink.set_property("caps", caps)

        pipeline.set_state(Gst.State.PLAYING)

        # Set the callback function on the appsink
        sink.set_property("emit-signals", True)
        sink.connect("new-sample", self.new_sample_cb, 0, 0)


        # pipeline_string = f"videotestsrc ! videoconvert ! videoscale ! video/x-raw,width={self.width},height={self.height},format=(string)RGB ! tee name=t1  \
        #     t1. ! queue ! appsink name=sink_right \
        #     t1. ! queue ! videoconvert ! autovideosink "
        # pipeline_string = f"videotestsrc ! videoconvert ! videoscale ! video/x-raw,width={self.width},height={self.height},format=(string)RGB ! appsink name=sink_right "
        pipeline_string = f"v4l2src device=/dev/video2 ! image/jpeg,width={self.width},height={self.height} ! jpegdec ! videoconvert   ! textoverlay text=right ! video/x-raw,format=(string)RGB ! appsink name=sink_right "


        # Create a GStreamer pipeline
        pipeline = Gst.parse_launch(pipeline_string)


        # Get the appsink element
        sink = pipeline.get_by_name("sink_right")
        if not sink:
            logging.error("no appsink element with name of 'sink_right'")

        # caps = Gst.Caps.from_string("video/x-raw,format=(string)RGB")
        # # Set caps on error_diffte(Gst.State.PLAYING)
        # sink.set_property("caps", caps)

        pipeline.set_state(Gst.State.PLAYING)

        # Set the callback function on the appsink
        sink.set_property("emit-signals", True)
        sink.connect("new-sample", self.new_sample_cb, 0, 1)

        # Run the GLib main loop
        loop = GLib.MainLoop()

        start = time.time()
        frame_count = 0
        ref_time_prev = None
        ref_time = None
        target = TARGET_DRAW_INTERVAL

        # FIXME:
        # PID_P = 0.9
        # PID_I = 0.0001
        # PID_D = 1
        PID_P = 1.0
        PID_I = 0.04
        PID_D = 0.2

        error_sigma = 0
        error_diff = 0
        error = 0
        error_prev = 0

        try:
            key = None
            while key != ord('q') and key != 27:
                # with self.mutex:
                frame = [ x for x in self.frames if x is not None]
                ref_0 = time.time()
                video_num = len(frame)
                if  video_num > 0:
                    frame = np.hstack(frame)
                    frame = cv2.resize(frame, (self.vis_width*video_num, self.vis_height))
                    frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
                    cv2.imshow("Frame from AppSink",  frame)
                    # logging.info("(ref_time - ref_time_prev)={}".format(1000*(ref_time - ref_time_prev))) if ref_time_prev else None

                else:
                    cv2.imshow("Frame from AppSink", np.zeros(shape=(self.vis_height, self.vis_height, 3)))

                ref_time = time.time()
                if ref_time_prev:
                    result = 1000*(ref_time - ref_time_prev)
                    # FIXME
                    # error = target - result
                    error = TARGET_DRAW_INTERVAL - result
                    error_sigma += error
                    error_diff = error - error_prev
                    # logging.info("target={}, result={}, error={}, error_sigma={}, error_diff={}".format(target, result, error, error_sigma, error_diff))
                    target = round(TARGET_DRAW_INTERVAL + PID_P*error + PID_I*error_sigma + PID_D*error_diff)
                    target = target if target > 0 else TARGET_DRAW_INTERVAL

                    error_prev = error
                ref_time_prev = ref_time

                key = cv2.waitKey(target)
                end = time.time()
                frame_count += 1

                elapsed = end - start
                if elapsed > 4.0:
                    fps = frame_count/elapsed
                    print("fps: {} = ({}/{})".format(fps, frame_count, elapsed))

                    # reset
                    start = time.time()
                    frame_count = 0

        except KeyboardInterrupt:
            pass
        finally:
            # Stop the pipeline and clean up
            pipeline.set_state(Gst.State.NULL)
            cv2.destroyAllWindows()


        # gst_loop = GLib.MainLoop()
        # try:
        #     gst_loop.run()
        # except KeyboardInterrupt as e:
        #     logging.info("Stopping GStreamer pipeline")


def main():
    logging.info('input arguments: {}'.format(sys.argv))
    parser = argparse.ArgumentParser(description='')
    # parser.add_argument('-p', '--port', action="store", dest='port', default=UDP_BASE_PORT, type=int, help='')
    # parser.add_argument('-r', '--rows', action="store", dest='rows', default=DEFAULT_VIDEO_ROWS, type=int, help='')
    # parser.add_argument('-c', '--cols', action="store",! videoscale ! video/x-raw,width={self.width},height={self.height},format=(string)RGB ! tee name=t1  \
    options=parser.parse_args(sys.argv[1:])

    viewer = Viewer()
    viewer.run()

if __name__ == '__main__':
    main()