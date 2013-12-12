#!/bin/sh

set -e

KEYSIZE=${CERTMAKE_KEYSIZE:-4096}

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

# define the two temp files and add trap hander for proper cleanup
INPUT_FILE=./tmp_input
CONFIG_FILE=./tmp_config.cnf
trap "rm -f $INPUT_FILE $CONFIG_FILE" EXIT INT TERM

# ask for main domain
whiptail --inputbox "Bitte geben Sie die Hauptdomain des SSL-Zertifikats ein:" 10 60 2> $INPUT_FILE
DOMAIN=$(cat $INPUT_FILE)

if [ "$DOMAIN" = "" ] ; then
	exit 1
fi

# ask for keysize
whiptail --inputbox "Key Size:" 10 60 $KEYSIZE 2> $INPUT_FILE
KEYSIZE=$(cat $INPUT_FILE)

if [ "$DOMAIN" = "" ] ; then
	exit 1
fi

CONFIG="$CONFIG\ncommonName = $DOMAIN"

# check if there's already an existing certificate
if [ -e "./$DOMAIN" ] ; then
	whiptail --yesno --defaultno "Es existiert bereits ein Zertifikat für diese Domain! Sind Sie sicher, dass die das vorhandene Zertifikat überschreiben wollen?" 10 60
	if [ "$?" = "0" ] ; then
		rm -rf "./$DOMAIN"
	fi
	if [ "$?" = "1" ] ; then
		exit 1
	fi
fi

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
EMAIL="$USER@uni-trier.de"
whiptail --inputbox "Bitte geben Sie eine E-Mail Adresse für das Zertifikat an:" 10 60 "$EMAIL" 2> $INPUT_FILE
EMAIL="$(cat $INPUT_FILE)"
CONFIG="$CONFIG\nemailAddress = $EMAIL"

CONFIG="$CONFIG\n\n[ v3_req ]"
if [ -n "$ALTNAMES" ] ; then
	CONFIG="$CONFIG\nsubjectAltName = $ALTNAMES"
fi

printf "$CONFIG" > $CONFIG_FILE
mkdir -p "$DOMAIN"
chmod 700 "$DOMAIN"
cp ./chain/unitrier-ca-chain.pem ./$DOMAIN/
openssl genrsa -out ./${DOMAIN}/server.key $KEYSIZE
chmod 600 ./${DOMAIN}/server.key
openssl req -new -key ./${DOMAIN}/server.key -out ./${DOMAIN}/server.csr -config $CONFIG_FILE
openssl x509 -req -days 14 -in ./${DOMAIN}/server.csr -signkey ./${DOMAIN}/server.key -out ./${DOMAIN}/server.crt	

