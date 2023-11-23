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

import gi
gi.require_version('Gst', '1.0')
gi.require_version('GstApp', '1.0')
from gi.repository import Gst, GObject, GstApp, GLib
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s')


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

class Viewer(object):
    def __init__(self, rows=DEFAULT_VIDEO_ROWS, cols=DEFAULT_VIDEO_COLS):
        self.rows = rows
        self.cols = cols

        self.width = 1920
        self.height = 1080

        self.vis_width = int(FIXED_HEIGHT* self.width/self.height)
        self.vis_height = int(FIXED_HEIGHT)

    def new_sample_cb(self, appsink, row, col):
        global data
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
            data = np.ndarray(shape=(height, width, 3), dtype=np.uint8, buffer=map_info.data)
            buffer.unmap(map_info)
            # Display the frame using OpenCV (you can replace this with your own processing)
            # start = time.time()
            self.img[col].set_data(data)
            # end = time.time()
            # elapsed = end - start
            # logging.info("elapsed={}".format(elapsed))


        # self.axes[row].imshow(data)
        # self.fig.canvas.draw()
        return Gst.FlowReturn.OK

    def run(self):
        self.fig, self.axes = plt.subplots(nrows=self.rows, ncols=self.cols)
        self.fig.set_figwidth(self.vis_width*2.0/self.fig.dpi)
        self.fig.set_figheight(self.vis_height/self.fig.dpi)

        self.fig.tight_layout()

        self.img = [None]*self.cols
        self.img[ID_LEFT] = self.axes[ID_LEFT].imshow(np.zeros((self.height, self.width, 3), dtype=np.uint8))
        self.img[ID_RIGHT] = self.axes[ID_RIGHT].imshow(np.zeros((self.height, self.width, 3), dtype=np.uint8))

        self.axes[ID_LEFT].set_title("left")
        self.axes[ID_RIGHT].set_title("right")

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
        pipeline_string = f"v4l2src device=/dev/video2 ! image/jpeg,width={self.width},height={self.height} ! jpegdec ! videoconvert   ! textoverlay text=right ! video/x-raw,format=(string)RGB ! appsink name=sink_right "


        # Create a GStreamer pipeline
        pipeline = Gst.parse_launch(pipeline_string)


        # Get the appsink element
        sink = pipeline.get_by_name("sink_right")
        if not sink:
            logging.error("no appsink element with name of 'sink_right'")

        # caps = Gst.Caps.from_string("video/x-raw,format=(string)RGB")
        # # Set caps on the appsink to ensure the correct format
        # sink.set_property("caps", caps)

        pipeline.set_state(Gst.State.PLAYING)

        # Set the callback function on the appsink
        sink.set_property("emit-signals", True)
        sink.connect("new-sample", self.new_sample_cb, 0, 1)

        # time.sleep(100)
        # Matplotlib setup

        # img = ax.imshow(np.zeros((480, 640, 3), dtype=np.uint8))

        # print(type(sink))
        # default_image = np.zeros((480, 640, 3), dtype=np.uint8)


        def update_frame(_):
            logging.info("update_frame")
            # # Pull a frame from the appsink
            # sample = sink.emit("pull-sample")
            # if sample is None:
            #     print("sample is None")
            #     img.set_array(default_image)
            #     return img,

            # buffer = sample.get_buffer()

            # # Map the buffer to read its data
            # success, map_info = buffer.map(Gst.MapFlags.READ)
            # if success:
            #     data = np.ndarray(shape=(480, 640, 3), dtype=np.uint8, buffer=map_info.data)
            #     img.set_array(data)
            #     buffer.unmap(map_info)

            return self.img[ID_LEFT], self.img[ID_RIGHT]
        # # Create an animation to update the frame
        ani = animation.FuncAnimation(self.fig, update_frame, blit=True, interval=20)

        # Show the plot
        try:
            plt.show()
        except KeyboardInterrupt as e:
            logging.info("Stopping GStreamer pipeline")


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
    # parser.add_argument('-c', '--cols', action="store", dest='cols', default=DEFAULT_VIDEO_COLS, type=int, help='')
    options=parser.parse_args(sys.argv[1:])

    viewer = Viewer()
    viewer.run()

if __name__ == '__main__':
    main()