Helper scripts for maintaining certificates
===========================================

The following tools are provided:

Check cert expire date for a individual host (and optional port).
```
$ ./tools/get-ssl-cert-expire-date.sh www.uni-trier.de 
Expires:	www.uni-trier.de:443	Oct 31 00:00:00 2015 GMT
```

Check all expire dates as defined from HOSTS/PORTS in the "config" file
and output them to stdout.
```
$ ./tools/get-all-ssl-cert-expire-dates.sh 
Expires:	136.199.199.104:443	Dec  3 13:48:50 2008 GMT
Expires:	136.199.8.220:993	Oct 31 00:00:00 2015 GMT
Expires:	136.199.8.220:995	Oct 31 00:00:00 2015 GMT
```

Check all HOSTS and PORTS defined in "config" and generate warning
MAILS if CERTS are about to expire.
```
$ ./cron-check-expire-dates.sh
```

Check all CERTs are valid for all hosts/ports defined in the "config":
```
./tools/verify-all-ssl-certs.sh tools/functions.sh
Valid:	136.199.199.214:443	Verify return code: -1 (failed-to-load-cert)
Valid:	136.199.8.220:993	    Verify return code: 0 (ok)
Valid:	136.199.8.220:995	    Verify return code: 0 (ok)
```