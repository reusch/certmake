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
req_extensions = v3_req

[ cert_type ]
nsCertType = server

[ req_dn ]
countryName             = DE
stateOrProvinceName     = Rheinland-Pfalz
localityName            = Trier
organizationName        = Universitaet Trier
organizationalUnitName  = ZIMK
"

V3REQ="
[ v3_req ]
"

# script
INPUT_FILE=./tmp_input

# ask for main domain
whiptail --inputbox "Bitte geben Sie die Hauptdomain des SSL-Zertifikats ein:" 10 60 2> $INPUT_FILE
DOMAIN=$(cat $INPUT_FILE)
CONFIG="$CONFIG\ncommonName = $DOMAIN"

# ask for alias domain list
whiptail --inputbox "Bitte geben Sie eine kommaseparierte Liste von Alias-Domains ein:" 10 60 2> $INPUT_FILE
ALIASDOMAINS=$(cat $INPUT_FILE)
COUNTER=0
ALTNAMES=""
if [ -n "$ALIASDOMAINS" ] ; then
	ALTNAMES="DNS:$DOMAIN"
	for aliasdomain in $(echo $ALIASDOMAINS | tr ',' '\ '); do
		ALTNAMES="$ALTNAMES, DNS:$aliasdomain"
	done
fi

# ask for email address
whiptail --inputbox "Bitte geben Sie eine E-Mail Adresse für das Zertifikat an:" 10 60 "webmaster@uni-trier.de" 2> $INPUT_FILE
EMAIL="$(cat $INPUT_FILE)"
CONFIG="$CONFIG\nemailAddress = $EMAIL"

CONFIG="$CONFIG\n\n[ v3_req ]"
if [ -n "$ALTNAMES" ] ; then
	CONFIG="$CONFIG\nsubjectAltName = $ALTNAMES"
fi

CONFIG_FILE=./tmp_config.cnf
trap "rm -f $INPUT_FILE $CONFIG_FILE" EXIT INT TERM

printf "$CONFIG" > $CONFIG_FILE
mkdir -p "$DOMAIN"
chmod 700 "$DOMAIN"
cp ./chain/unitrier-ca-chain.pem ./$DOMAIN/
openssl genrsa -out ./${DOMAIN}/server.key $KEYSIZE
chmod 600 ./${DOMAIN}/server.key
openssl req -new -key ./${DOMAIN}/server.key -out ./${DOMAIN}/server.csr -config $CONFIG_FILE
openssl x509 -req -days 14 -in ./${DOMAIN}/server.csr -signkey ./${DOMAIN}/server.key -out ./${DOMAIN}/server.crt	

