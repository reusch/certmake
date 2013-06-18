#!/bin/sh

set -e

download_and_verify() {
    URL="$1"
    SHA1="$2"
    NAME=$(basename $URL)
    CRT_NAME=${NAME%.crt}.pem
    wget --quiet $URL
    openssl x509 -in $NAME -out $CRT_NAME -inform DER -outform PEM
    if ! openssl x509 -noout -fingerprint -in $CRT_NAME | grep -q "$SHA1"; then
        echo "ERROR: failed to verify $CRT_NAME, hash mismatch"
        exit 1
    fi
} 

# cleanup
rm *.crt

# Zertifikat 1 (Wurzelzertifikat Deutsche - Telekom Root CA2) 
download_and_verify \
    http://www.uni-trier.de/fileadmin/urt/sicherheit/Zertifikate/Wurzelzertifikat/Wurzelzertifikate/g_rootcert.crt \
    85:A4:08:C0:9C:19:3E:5D:51:58:7D:CD:D6:13:30:FD:8C:DE:37:BF

# Zertifikat 2 (DFN-PCA Zertifikat - PCA Global  G01) 
download_and_verify \
    http://www.uni-trier.de/fileadmin/urt/sicherheit/Zertifikate/Wurzelzertifikat/DFN-PCA_Zertifikat/g_intermediatecacert.crt \
    F0:28:8F:DA:C6:3A:F7:9A:31:9A:E9:72:F3:95:09:0E:A3:EF:E9:45 

# Zertifikat 3 (RHRK Zertifikat - RHRK CA G02) 
download_and_verify \
    http://www.uni-trier.de/fileadmin/urt/sicherheit/Zertifikate/Wurzelzertifikat/RHRK_CA_in_der_DFN_PKI_Zertifikat/g_cacert.crt \
    64:1E:33:33:0D:EB:CD:30:C0:8D:38:DB:A9:51:92:63:C9:C5:7E:37 

# and concat them in the right order (order is important!)
TARGET=unitrier-ca-chain.pem
cat g_cacert.pem g_intermediatecacert.pem g_rootcert.pem > $TARGET
echo "generated chain $TARGET"
