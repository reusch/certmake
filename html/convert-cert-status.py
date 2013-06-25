#!/usr/local/bin/python

import datetime
import dateutil.parser
import os
import sys

import jinja2

class CertStatus(object):
    """Represents the status of a given certificate """

    @classmethod
    def from_line(cls, line):
        IP_AND_PORT=1
        DNSNAME=2
        VERIFY_RESULT=3
        ALT_SUBJECTS=4
        EXPIRE_DATE=5
        line = line.strip()
        line=line.split("\t")
        d = {}
        d["ip"] = line[IP_AND_PORT].split(":")[0]
        d["port"] = line[IP_AND_PORT].split(":")[1]
        d["dnsname"] = line[DNSNAME]
        d["verify_result"] = line[VERIFY_RESULT]
        d["verify_ok"] = "Verify return code: 0 " in d["verify_result"]
        d["alt_subjects"] = line[ALT_SUBJECTS].split(",")
        d["expire_date"] = line[EXPIRE_DATE]
        d["expire_days_left"] = cls._get_expire_days_left(d["expire_date"])
        return CertStatus(**d)

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
    with open(infile) as f:
        return parse_cert_status_stream(f)


def parse_cert_status_stream(stream):
    all_certs = []
    for line in stream.readlines():
        all_certs.append(CertStatus.from_line(line))
    return all_certs


def render_cert_status(all_certs):
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(os.path.dirname(__file__)))
    template = env.get_template("cert-status.jinja2")
    return template.render({
            'all_certs': all_certs,
            'now': datetime.datetime.now(),
            })


def generate_html_from_file(filename):
    all_certs = parse_cert_status_file(filename)
    html = render_cert_status(all_certs)
    return html


if __name__ == "__main__":
    html = generate_html_from_file(sys.argv[1])
    print html
