#!/bin/sh

set -e

HERE=$(dirname $0)
. $HERE/functions.sh

# build NMAP line

#     https,ssmtp,ldaps,imaps,pop3s 
PORTS="443,465,636,993,995"
HOSTS="136.199.8.1-254 136.199.199.1-254"

OUT=$(nmap --open -sT -P0 -p $PORTS $HOSTS -oG -|grep 'Ports:')

HOST_IP=$(echo "$OUT" | cut -f1 | cut -d' ' -f2)
PORTS=$(echo "$OUT" | cut -f2 | cut -f2 -d: )

for port_string in $PORTS; do
    port=$(echo $port_string | cut -d/ -f1)
    echo check_server_cert_expire $HOST_IP $port
    check_server_cert_expire $HOST_IP $port
done

