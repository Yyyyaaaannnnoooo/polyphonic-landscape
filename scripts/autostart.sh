#!/bin/bash
export PATH=/usr/local/bin:$PATH
export DISPLAY=:0.0
sleep 10 # can be lower (5) for rpi3
jackd -P75 -p16 -dalsa -dhw:0 -r44100 -p1024 -n3
sclang ../sc/sample-player/polyphonic-landscapes.scd
