#!/bin/bash

set -x

HOST=127.0.0.1

gst-launch-1.0 -v  tcpserversrc host=$HOST port=5000 ! tcpserversink host=$HOST port=5001
