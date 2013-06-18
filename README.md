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

Import the cert-$nr.pem cert:
```
$ ./import-dfn-pem.sh cert-<nr>.pem <servername-dir>
```

And then scp the directory with the certificates to the server and deploy
them.


Tools
-----
There is also some useful stuff in the tools/ directory, check
README.tools for more info.
