#!/bin/sh

docker run -ti --rm -p 55038:5038 --name=asterisk-crystal \
  -v ${PWD}/asterisk/manager.conf:/etc/asterisk/manager.conf \
  -v ${PWD}/asterisk/manager.d/ahn.conf:/etc/asterisk/manager.d/ahn.conf \
  -v ${PWD}/asterisk/sip.conf:/etc/asterisk/sip.conf \
  -v ${PWD}/asterisk/extensions.ael:/etc/asterisk/extensions.ael \
  -v ${PWD}/asterisk/crystal:/root/crystal \
  andrius/docker-asterisk13 asterisk -vvvddddc
