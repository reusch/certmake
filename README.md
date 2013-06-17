Tiny wrapper to make DFN certificate creation trivial
=====================================================

Just run "./certmakter.sh" and follow the instructions.

The certificates are generated in a <servername> dir and contain:
```
server.csr - certficiate signing request
server.crt - self-signed certificate (to be replaced)
server.key - private key
unitrier-ca-chain.pem - uni trier chain
```

Then submit the server.csr to http://pki.pca.dfn.de/rkrk-ca/uni-trier.
Get approval from the local DFN PKI person. 

Wait for the cert-$nr.pem mail from certify@uni-trier.de. 

Replace server.crt with the real cert-$nr.pem cert:
```
$ cp cert-*.pem server.crt
```

And then scp the directory with the certificates to the server and deploy
them.



