#!/bin/sh

HERE=$(dirname $0)
. $HERE/config

# Takes a list of hosts in $1 and a list of ports $2 and outputs 
# (in the nmap format) the open ports in the host range
find_all_ssl_hosts() {
    HOSTS="$1"
    PORTS="$2"
    nmap --open -sT -P0 -p $PORTS $HOSTS -oG - | grep 'Ports:'
}

gethostbyaddr() {
    IP="$1"
    HOSTNAME=$(python -c \
        "import socket; print socket.gethostbyaddr(\"$IP\")[0].split('.')[0]")
    printf $HOSTNAME
}

# Reads nmap -oG output and checks if the cert is valid
verify_cert_is_valid() {
    while read LINE; do
        SERVER=$(echo "$LINE" | cut -f1 | cut -d' ' -f2)
        PORTS=$(echo "$LINE" | cut -f2 | cut -f2 -d: )
        HOSTNAME=$(gethostbyaddr "$SERVER")
        
        for PORT_STRING in $PORTS; do
            PORT=$(echo $PORT_STRING | cut -d/ -f1)
            # meh, this is more complicated than it should be!
            OPENSSL=$(openssl s_client -showcerts  \
                -CAfile /etc/ssl/certs/ca-certificates.crt \
                -connect ${SERVER}:${PORT} \
                < /dev/null 2>/dev/null | grep Verify \
                || printf "Verify return code: -1 (failed-to-load-cert)")
            VALID="$OPENSSL"
            DNS=$(get_cert_alternative_subject_names $SERVER)
            printf "Status:\t$SERVER:$PORT\t$HOSTNAME\t$VALID\t[$DNS]\n"
        done
    done
}

get_cert_alternative_subject_names() {
    SERVER_AND_PORT="$1"

    # meh, this is more complicated than it should be!
    OPENSSL=$(openssl s_client -showcerts  -connect ${SERVER}:${PORT} \
        < /dev/null 2>/dev/null | \
        openssl x509 -noout -subject -text \
        || printf "DNS: failed-to-load-cert")
    DNS=$(echo "$OPENSSL" | grep DNS: | cut -f2 -d= | \
          tr -d '[:blank:]' | sed s/'DNS:'//g)
    printf "$DNS"
}

# Reads nmap -oG output and gets the cert expire date for each port
#
# Input lines look like:
#  Host: 136.199.199.104 (urts104.uni-trier.de)	Ports: 443/open/tcp//https///	Ignored State: filtered (4)
get_cert_expire_dates() {
    while read LINE; do
        SERVER=$(echo "$LINE" | cut -f1 | cut -d' ' -f2)
        PORTS=$(echo "$LINE" | cut -f2 | cut -f2 -d: )
        
        for PORT_STRING in $PORTS; do
            PORT=$(echo $PORT_STRING | cut -d/ -f1)
            # meh, this is more complicated than it should be!
            OPENSSL=$(openssl s_client -showcerts  -connect ${SERVER}:${PORT} \
                < /dev/null 2>/dev/null | \
                openssl x509 -noout -subject -dates \
                || printf "notAfter=failed-to-load-cert")
            END_DATE=$(echo "$OPENSSL" | grep notAfter | cut -f2 -d=)
            printf "Expires:\t$SERVER:$PORT\t$END_DATE\n"
        done
    done
}

# reads the output of get_cert_expire_dates and generate warning mails
# if a cert is about to expire
#
# Input lines look like:
#   Expires: 136.199.199.104:443	Dec  3 13:48:50 2008 GMT
warn_about_cert_expire_dates() {
    while read LINE; do
        HOST_AND_IP=$(echo "$LINE" | cut -f2)
        END_DATE=$(echo "$LINE" | cut -f3)
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
        elif [ "$END_TIME_EPOCH" -lt $((NOW_EPOCH + 60*60*24*${MIN_WARN_DAYS})) ]; 
        then
            mail_warning "$WARN_MAILTO" \
                "Cert expires soon: $SERVER:$PORT" \
                "Cert for $SERVER:$PORT expires in less than $MIN_WARN_DAYS days
Expire date is $END_DATE"
        fi
    done
}

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

