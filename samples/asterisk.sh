#!/bin/sh

docker run -ti --rm -p 55038:5038 \
  -v ${PWD}/asterisk/sip.conf:/etc/asterisk/sip.conf \
  -v ${PWD}/asterisk/manager.conf:/etc/asterisk/manager.conf \
  -v ${PWD}/asterisk/manager.d/ahn.conf:/etc/asterisk/manager.d/ahn.conf \
  andrius/alpine-asterisk:14
  # andrius/docker-asterisk13
