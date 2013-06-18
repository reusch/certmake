#!/bin/sh

set -e

HERE=$(dirname $0)
. $HERE/functions.sh

# find all ssl enabled hosts
find_all_ssl_hosts "$HOSTS" "$PORTS"  > ssl_hosts.txt
# get their expire dates
get_cert_expire_dates < ssl_hosts.txt > ssl_expire_dates.txt
# and generate warning mails if needed
warn_about_cert_expire_dates < ssl_expire_dates.txt
