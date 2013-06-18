
# first warning level
MIN_WARN_DAYS=42
WARN_MAILTO=michael.vogt@uni-trier.de
#WARN_MAILTO=shen@uni-trier.de

# escalate
MIN_ESCALATE_DAYS=14
WARN_ESCALATE_MAILTO=zentrale-systeme@zimk.uni-trier.de

# really escalate(!)
MIN_MIN_DAYS=7
WARN_MIN_MIN_MAILTO=leitung@zimk.uni-trier.de

# only pretend
DRY_RUN=1
DEBUG=1

mail_warning() {
    MAILTO="$1"
    SUBJECT="$2"
    BODY="$3"
   
    if [ $DRY_RUN -eq 1 ]; then 
        # debug
        echo "To: $MAILTO"
    	echo "Subject: $SUBJECT"
	echo
    	echo "$BODY"
    else
        # really send mail
        echo "$BODY" | mail $MAILTO -s "$SUBJECT" 
    fi
}

check_server_cert_expire() {
  SERVER="$1"
  PORT="$2"

  # FIXME: add check for warnings from openssl too
  OUT=$(openssl s_client -showcerts  -connect ${SERVER}:${PORT} \
         < /dev/null 2>/dev/null | \
         openssl x509 -noout -subject -dates)

  END_DATE=$(echo "$OUT" | grep notAfter | cut -f2 -d=)
  END_TIME_EPOCH=$(date -d "$END_DATE" +%s)
    
  NOW_EPOCH=$(date +%s)

  if [ $DEBUG -gt 0 ]; then
    echo "DEBUG: $SERVER:$PORT, $END_DATE"
  fi

  if [ "$END_TIME_EPOCH" -lt $((NOW_EPOCH + 60*60*24*${MIN_MIN_DAYS})) ]; 
  then
      mail_warning "$WARN_MIN_MIN_MAILTO" \
          "CERT EXPIRES SOON: $SERVER:$PORT" \
          "Cert for $SERVER:$PORT expires in less than $MIN_MIN_DAYS days
Expire date is $END_DATE"
    return 1
  elif [ "$END_TIME_EPOCH" -lt $((NOW_EPOCH + 60*60*24*${MIN_ESCALATE_DAYS})) ]; 
  then
      mail_warning "$WARN_ESCALATE_MAILTO" \
          "Cert expires soon: $SERVER:$PORT" \
          "Cert for $SERVER:$PORT expires in less than $MIN_ESCALATE_DAYS days
Expire date is $END_DATE"
    return 1
  elif [ "$END_TIME_EPOCH" -lt $((NOW_EPOCH + 60*60*24*${MIN_WARN_DAYS})) ]; 
  then
      mail_warning "$WARN_MAILTO" \
          "Cert expires soon: $SERVER:$PORT" \
          "Cert for $SERVER:$PORT expires in less than $MIN_WARN_DAYS days
Expire date is $END_DATE"
    return 1
  fi

  return 0
}
