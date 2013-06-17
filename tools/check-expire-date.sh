#!/bin/sh

set -e

HERE=$(dirname $0)
. $HERE/functions.sh

# get the server
if [ -z "$1" ]; then
    echo "need a server name (and optional port) as argument"
    exit 1
fi
SERVER="$1"

# get the port
PORT="$2"
if [ -z "$PORT" ]; then
    PORT=443
fi

# warn if needed
check_server_cert_expire "$SERVER" "$PORT"

