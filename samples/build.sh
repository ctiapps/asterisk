#!/bin/sh

crystal build --no-debug \
  -o samples/asterisk/crystal/ami/connect-disconnect \
  samples/ami/connect-disconnect.cr

crystal build --no-debug \
  -o samples/asterisk/crystal/ami/multi-line-event \
  samples/ami/multi-line-event.cr

crystal build --no-debug \
  -o samples/asterisk/crystal/agi/basic \
  samples/agi/basic.cr

crystal build --no-debug \
  -o samples/asterisk/crystal/agi/basic-fastagi \
  samples/agi/basic-fastagi.cr


docker exec -ti asterisk-crystal mkdir -p /var/lib/asterisk/agi-bin
docker cp samples/asterisk/crystal/agi/basic asterisk-crystal:/var/lib/asterisk/agi-bin/
docker cp samples/asterisk/crystal/agi/basic-fastagi asterisk-crystal:/var/lib/asterisk/agi-bin/
docker exec -ti asterisk-crystal chown -R asterisk:asterisk /var/lib/asterisk/agi-bin

