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
