#!/bin/bash

source /entrypoint/cc_certificates.sh

cd /vlc && sudo -u vlc HOSTIP=$HOSTIP ISSUER=$ISSUER ./vlc --sout="#chromecast{ip=$ISSUER}" "$@"
