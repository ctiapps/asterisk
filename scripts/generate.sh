#!/bin/sh

crystal scripts/generate-agi-commands.cr
crystal tool format src/asterisk/agi/commands.cr
crystal scripts/generate-ari.cr
crystal tool format src/asterisk/ari/
./tmp/build-docs
