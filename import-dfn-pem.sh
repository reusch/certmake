#!/bin/sh

set -e

make_courier_cert() {
    mkdir -p courier
    install -m 0600 server.crt courier/courier.pem
    cat server.key >> courier/courier.pem
    install -m 0600 ../chain/unitrier-ca-chain.pem courier/tls_trustcerts.txt
    cat > courier/README <<EOF
Certs created based on:
http://www.digicert.com/ssl-certificate-installation-courier-imap.htm
EOF
}

make_postfix_cert() {
    mkdir -p postfix
    install -m 0600 server.crt postfix/server.pem
    cat ../chain/unitrier-ca-chain.pem >> postfix/server.pem
    install -m 0600 server.key postfix/server.key
    cat > postfix/README <<EOF
Certs created based on:
http://www.postfix.org/TLS_README.html#server_cert_key
EOF
}

make_idrac_cert() {
    mkdir -p idrac
    export PASS=""
    install -m 0600 server.key idrac/server.key
    install -m 0600 server.crt idrac/server.pem
    cat ../chain/unitrier-ca-chain.pem >> idrac/server.pem
    openssl pkcs12 -export -in idrac/server.pem -inkey idrac/server.key -out idrac/all.p12 -clcerts -passin env:PASS -passout env:PASS -password env:PASS
    openssl pkcs12 -in idrac/all.p12 -out idrac/finalcert.pem -passout env:PASS -passin env:PASS -passout env:PASS
    rm -f idrac/server.pem idrac/all.p12
    cat > idrac/README <<EOF
Certs created based on:
https://redmine.uni-trier.de/projects/wlan/wiki/SSL-Zertifikate_f%C3%BCr_WLAN-Controller
http://serverfault.com/questions/485426/install-existing-ssl-certificate-on-dell-idrac7
EOF
}

make_apache_cert() {
    mkdir -p apache
    install -m 0600 server.crt apache/server.crt
    cat ../chain/unitrier-ca-chain.pem >> apache/chain.pem
    install -m 0600 server.key apache/server.key
    cat > apache/README <<EOF
Certs created based on:
http://wiki.cacert.org/SimpleApacheCert
EOF
    
}


SIGNED_CRT="$1"
if [ ! -f "$SIGNED_CRT" ]; then
    echo "need the dfn pem file as the first argument"
    exit 1
fi

TARGET_DIR="$2"
if [ ! -d "$TARGET_DIR" ]; then
    echo "need the server directory as the second argument"
    exit 1
fi

install -m 0600 "$SIGNED_CRT" "${TARGET_DIR}/server.crt"

# generate various chains
cd "$TARGET_DIR"

# generate cert for some of our apps
make_courier_cert
make_postfix_cert
make_apache_cert
make_idrac_cert
