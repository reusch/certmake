#!/bin/sh

set -e

KEYSIZE=4096

CONFIG="
[ req ]
default_bits = $KEYSIZE
encrypt_key = yes
distinguished_name = req_dn
x509_extensions = cert_type
prompt = no

[ cert_type ]
nsCertType = server

[ req_dn ]
countryName             = DE
stateOrProvinceName     = Rheinland-Pfalz
localityName            = Trier
organizationName        = Universitaet Trier
organizationalUnitName  = ZIMK
"

# script
INPUT_FILE=tmp_input

# ask for domain list
whiptail --inputbox "Bitte geben Sie eine kommaseparierte Liste von Domains ein, die im Zertifikat enthalten sein sollen:" 10 60 2> $INPUT_FILE
DOMAINS=$(cat $INPUT_FILE)
COUNTER=0
for domain in $(echo $DOMAINS | tr ',' '\ '); do
        if [ -z "$SERVERNAME" ]; then
                SERVERNAME="$domain"
        fi
	CONFIG="$CONFIG\\n$COUNTER.commonName = $domain"
	COUNTER=$((COUNTER + 1))
done

# ask for email address
whiptail --inputbox "Bitte geben Sie eine E-Mail Adresse für das Zertifikat an:" 10 60 "webmaster@uni-trier.de" 2> $INPUT_FILE
EMAIL="$(cat $INPUT_FILE)"
CONFIG="$CONFIG\nemailAddress = $EMAIL"

CONFIG_FILE=tmp_config.cnf
echo "$CONFIG" > $CONFIG_FILE
dd if=/dev/random of=./${SERVERNAME}.rand bs=$KEYSIZE count=1 2>/dev/null
openssl genrsa -out ${SERVERNAME}.key $KEYSIZE
openssl req -new -key ${SERVERNAME}.key -out ${SERVERNAME}.csr -config $CONFIG_FILE
openssl x509 -req -days 365 -in ${SERVERNAME}.csr -signkey ${SERVERNAME}.key -out ${SERVERNAME}.crt	

trap "rm -f ./${SERVERNAME}.rand; rm $INPUT_FILE; rm $CONFIG_FILE" EXIT INT TERM
