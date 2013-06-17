#!/bin/sh

set -e

# minimal warning days
MIN_DAYS=42

check_server_cert_expire() {
  SERVER="$1"
  PORT="$2"

  # FIXME: add check for warnings from openssl too
  OUT=$(openssl s_client -showcerts  -connect ${SERVER}:${PORT} \
         < /dev/null 2>/dev/null | \
         openssl x509 -noout -subject -dates )

  END_DATE=$(echo "$OUT" | grep notAfter | cut -f2 -d=)
  END_TIME_EPOCH=$(date -d "$END_DATE" +%s)
    
  NOW_EPOCH=$(date +%s)
  WARN_EPOCH=$((NOW_EPOCH + 60*60*24*${MIN_DAYS}))
  
  if [ "$END_TIME_EPOCH" -lt "$WARN_EPOCH" ]; then
    return 1
  fi
  return 0
}

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
if ! check_server_cert_expire "$SERVER" "$PORT"; then
    echo "WANING: cert for $SERVER:$PORT expires in less than $MIN_DAYS days "
    echo "Expire date is $END_DATE"
fi

