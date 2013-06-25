#!/usr/bin/python

import datetime
import dateutil.parser
import sys

import jinja2

class Cert:
    IP_AND_PORT=1
    DNSNAME=2
    VERIFY_RESULT=3
    ALT_SUBJECTS=4
    EXPIRE_DATE=5
    
    @classmethod
    def from_line(cls, line):
        line = line.strip()
        line=line.split("\t")
        d = {}
        d["ip"] = line[cls.IP_AND_PORT].split(":")[0]
        d["port"] = line[cls.IP_AND_PORT].split(":")[1]
        d["dnsname"] = line[cls.DNSNAME]
        d["verify_result"] = line[cls.VERIFY_RESULT]
        d["verify_ok"] = "Verify return code: 0 " in d["verify_result"]
        d["alt_subjects"] = line[cls.ALT_SUBJECTS]
        d["expire_date"] = line[cls.EXPIRE_DATE]
        d["expire_days_left"] = cls._get_expire_days_left(d["expire_date"])
        return Cert(**d)

    @classmethod
    def _get_expire_days_left(cls, expire_date_str):
        try:
            expire_date = dateutil.parser.parse(expire_date_str, ignoretz=True)
            timedelta = expire_date - datetime.datetime.utcnow()
            return timedelta.days
        except ValueError:
            return 0
    
    def __init__(self, **kwargs):
        for k,v in kwargs.items():
            setattr(self, k, v)


def parse_cert_status_file(infile):
    all_certs = []
    with open(infile) as f:
        for line in f.readlines():
            all_certs.append(Cert.from_line(line))
    return all_certs


if __name__ == "__main__":
    all_certs = parse_cert_status_file(sys.argv[1])
    
    template_file = sys.argv[2]
    template = jinja2.Template(open(template_file).read())
    print template.render({
            'all_certs': all_certs,
            'now': datetime.datetime.now(),
            })
