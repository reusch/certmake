#!/bin/sh

set -e

HERE=$(dirname $0)
. $HERE/functions.sh

find_all_ssl_hosts "$HOSTS" "$PORTS"  | get_cert_expire_dates 
