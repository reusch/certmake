#!/bin/sh

set -e

HERE=$(dirname $0)
cd $HERE

STATIC="css img js"
TARGETDIR=/var/www/certstatus
TARGET=$TARGETDIR/index.html

# deploy static stuff
cp -ar $STATIC $TARGETDIR

# deploy info
../tools/verify-all-ssl-certs.sh > ${TARGET}
./convert-cert-status.py cert-status.txt > ${TARGET}.tmp
mv ${TARGET}.tmp $TARGET
