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
import threading

import gi
import cairo
gi.require_foreign('cairo')
gi.require_version('Gst', '1.0')
gi.require_version('GstApp', '1.0')
gi.require_version('Gtk', '3.0')
from gi.repository import Gst, Gtk, GObject, GstApp, GLib

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

DEFAULT_BPP=4

ID_LEFT=0
ID_RIGHT=1
FIXED_HEIGHT=480

class DrawingArea(Gtk.DrawingArea):
    def __init__(self, width, height):
        Gtk.DrawingArea.__init__(self)

        self.set_size_request(width, height)

        self.fixed_width = width
        self.fixed_height = height

        self.connect("draw", self.on_draw)

        self.pixmap = np.zeros((height, width, DEFAULT_BPP), dtype=np.uint8)

    def on_draw(self, widget, cr):
        # logging.info("on_draw")
        # Create a surface and context for Cairo drawing
        #
        # reference: https://pycairo.readthedocs.io/en/latest/tutorial/numpy.html#numpy-imagesurface
        #
        surface = cairo.ImageSurface.create_for_data(
            self.pixmap, cairo.FORMAT_ARGB32,
            self.pixmap.shape[1], self.pixmap.shape[0]
        )
        # print(self.bitmap.shape, self.bitmap.strides)
        # Draw a red rectangle on the surface
        # cr.set_source_rgb(1, 0, 0)
        # cr.rectangle(10, 10, 100, 50)
        # cr.fill()

        # reference: https://pycairo.readthedocs.io/en/latest/reference/matrix.html#cairo.Matrix.scale

        h, w = self.pixmap.shape[:2]
        cr.scale(self.fixed_width/w, self.fixed_height/h)

        cr.set_source_surface(surface, 0.0, 0.0)

        # Convert the Cairo surface to a GdkPixbuf
        # pixbuf = Gdk.pixbuf_get_from_surface(surface, 0, 0, self.bitmap.shape[1], self.bitmap.shape[0])

        # Draw the GdkPixbuf on the widget's window
        # widget.get_window().draw_pixbuf(
        #     widget.get_style().fg_gc[Gtk.StateType.NORMAL],
        #     pixbuf, 0, 0, 0, 0, self.bitmap.shape[1], self.bitmap.shape[0],
        #     Gdk.RGB_DITHER_NONE, 0, 0
        # )

        #
        # reference: https://stackoverflow.com/questions/10270080/how-to-draw-a-gdkpixbuf-using-gtk3-and-pygobject
        #
        cr.paint()

    def set_pixmap(self, pixmap):
        self.pixmap = pixmap



class Viewer(object):
    def __init__(self, rows=DEFAULT_VIDEO_ROWS, cols=DEFAULT_VIDEO_COLS):
        self.rows = rows
        self.cols = cols

        self.width = 1920
        self.height = 1080

        self.vis_width = int(FIXED_HEIGHT* self.width/self.height)
        self.vis_height = int(FIXED_HEIGHT)

        self.view_left = DrawingArea(self.vis_width, self.vis_height)
        self.view_right = DrawingArea(self.vis_width, self.vis_height)

        self.views = (self.view_left, self.view_right)

    def new_sample_cb(self, appsink, row, col):
        # with self.mutex:

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
            data = np.ndarray(shape=(height, width, DEFAULT_BPP), dtype=np.uint8, buffer=map_info.data)
            buffer.unmap(map_info)

            view = self.views[col]
            view.set_pixmap(data.copy())
            GLib.idle_add(view.queue_draw)

        return Gst.FlowReturn.OK

    def run(self):
        # Initialize GStreamer
        Gst.init(None)

        # GStreamer pipeline definition
        # pipeline_string = f"v4l2src device=/dev/video0 ! image/jpeg,width={self.width},height={self.height} ! jpegdec ! videoconvert  ! video/x-raw,format=(string)BGRA ! tee name=t0 \
        #     t0. ! queue ! appsink name=sink_left \
        #     t0. ! queue ! videoconvert ! autovideosink "
        pipeline_string = f"v4l2src device=/dev/video0 ! image/jpeg,width={self.width},height={self.height} ! jpegdec ! videoconvert ! textoverlay text=left ! video/x-raw,format=(string)BGRA ! appsink name=sink_left "

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
        pipeline_string = f"v4l2src device=/dev/video2 ! image/jpeg,width={self.width},height={self.height} ! jpegdec ! videoconvert   ! textoverlay text=right ! video/x-raw,format=(string)BGRA ! appsink name=sink_right "


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

        # Draw
        win = Gtk.Window(title="Stereo Video Viewer Gtk 3.0")
        win.set_default_size(2*self.vis_width, self.vis_height)
        grid = Gtk.Grid()
        grid.add(self.view_left)
        grid.attach(self.view_right, 1, 0, 1, 1)
        win.add(grid)
        win.connect("destroy", Gtk.main_quit)
        win.show_all()

        try:
            Gtk.main()
        except KeyboardInterrupt as e:
            logging.info("Stopping GStreamer pipeline")
        finally:
            # Gtk.main_quit()
            pass

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
