#!/bin/bash

set -x

#HOST=127.0.0.1
HOST=172.31.13.19 # US server

gst-launch-1.0 -v  tcpserversrc host=$HOST port=5000 ! tcpserversink host=$HOST port=5001
