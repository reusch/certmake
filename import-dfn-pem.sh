#!/bin/sh

set -e

SIGNED_CRT="$1"
if [ ! -f "$SIGNED_CRT" ]; then
    echo "need the dfn pem file as the first argument"
    exit 1
fi

TARGET_DIR="$2"
if [ ! -d "$TARGET_DIR" ]; then
    echo "need the server directory as the second argument"
    exit 1
fi

install -m 0600 "$SIGNED_CRT" "${TARGET_DIR}/server.crt"

# generate various chains
cd "$TARGET_DIR"

#TODO: generate various chains
# http://www.digicert.com/ssl-certificate-installation-courier-imap.htm
