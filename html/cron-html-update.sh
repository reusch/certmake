#!/bin/sh

set -e

HERE=$(dirname $0)
cd $HERE

../tools/verify-all-ssl-certs.sh > cert-status.txt
./convert-cert-status.py cert-status.txt > cert-status.html.tmp
mv cert-status.html.tmp cert-status.html
