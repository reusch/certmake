#!/bin/sh

set -e

HERE=$(dirname $0)
. $HERE/functions.sh

find_all_ssl_hosts "$HOSTS" "$PORTS"  | verify_cert_is_valid
