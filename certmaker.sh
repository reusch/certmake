#!/bin/bash

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
INPUT_FILE=`/bin/tempfile`

# ask for domain list
whiptail --inputbox "Bitte geben Sie eine kommaseparierte Liste von Domains ein, die im Zertifikat enthalten sein sollen:" 10 60 2> $INPUT_FILE
DOMAINS=`cat $INPUT_FILE`
COUNTER=0
for domain in ${DOMAINS//,/ } ; do
	CONFIG=`echo -e "$CONFIG\\\\n$COUNTER.commonName = $domain"`
	COUNTER=`expr $COUNTER + 1`
done

# ask for email address
whiptail --inputbox "Bitte geben Sie eine E-Mail Adresse für das Zertifikat an:" 10 60 "webmaster@uni-trier.de" 2> $INPUT_FILE
EMAIL=`cat $INPUT_FILE`
CONFIG=`echo -e "$CONFIG\\\\nemailAddress = $EMAIL"`

CONFIG_FILE=`/bin/tempfile`
echo "$CONFIG" > $CONFIG_FILE
/bin/dd if=/dev/random of=./server.rand bs=$KEYSIZE count=1 2>/dev/null
/usr/bin/openssl genrsa -out server.key $KEYSIZE
/usr/bin/openssl req -new -key server.key -out server.csr -config $CONFIG_FILE
/usr/bin/openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt	
/bin/rm -f ./server.rand
/bin/rm $INPUT_FILE
/bin/rm $CONFIG_FILE