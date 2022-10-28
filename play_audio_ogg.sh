#!/bin/sh

FILE_LOC0=./data/VrSystemIsReady.ogg
gst-launch-1.0 -v filesrc location=$FILE_LOC0 ! oggdemux ! vorbisdec ! audioconvert ! audioresample ! volume volume=1.2 ! level  ! autoaudiosink
