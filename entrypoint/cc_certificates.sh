#!/bin/bash
ISSUER=$(gnutls-cli --print-cert --no-ca-verification $CHROMECASTIP:8009 </dev/null | sed -n '7p' | awk '{split($0,a,"="); print a[3]}' | awk '{split($0,a,"'\''"); print a[1]}')

echo "$CHROMECASTIP  $ISSUER" >> /etc/hosts

gnutls-cli --print-cert --no-ca-verification $ISSUER:8009 </dev/null| sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /usr/local/share/ca-certificates/chromecast.crt

update-ca-certificates