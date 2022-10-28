#!/bin/sh

FILE_LOC0=./data/Alesis-Sanctuary-QCard-Choir-Aah-C4.wav
FILE_LOC1=./data/Alesis-Sanctuary-QCard-Choir-Ooh-C4.wav
FILE_LOC2=./data/Ensoniq-ZR-76-03-Dope-85.wav

gst-launch-1.0 filesrc location=$FILE_LOC0 ! wavparse ! audioconvert ! audioresample ! volume volume=0.5 ! level  ! adder name=mixer ! autoaudiosink \
  filesrc location=$FILE_LOC1 ! wavparse ! audioconvert ! audioresample ! volume volume=1.0 ! level  ! mixer.
