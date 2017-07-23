#!/bin/sh

crystal build --no-debug \
  -o samples/asterisk/crystal/ami/connect-disconnect \
  samples/ami/connect-disconnect.cr

crystal build --no-debug \
  -o samples/asterisk/crystal/ami/multi-line-event \
  samples/ami/multi-line-event.cr
