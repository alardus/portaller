#!/usr/bin/python

"""
Produces a Linux Netfilter u32 rule to match DNS requests for a given
domain name and/or a given query type.

Typical usage:
% python generate-netfilter-u32-rule.py --qname ripe.net --qtype ANY
Can be embedded in iptables' invocations for instance:
rule=$(python generate-rule.py args...)
iptables [...] --match u32 --u32 "$rule" 

Written by Stephane Bortzmeyer <bortzmeyer@nic.fr>
"""

import sys
import getopt
import string

def usage(msg=None):
    print >>sys.stderr, "Usage: %s --qname FQDN [--qtype TYPE] [--bufsize SIZE]" % sys.argv[0]
    if msg is not None:
        print >>sys.stderr, msg

hexstring = []
maskstring = []

types = { # http://www.iana.org/assignments/dns-parameters
    'A': 1,
    'NS': 2,
    'SOA': 6,
    'MX': 15,
    'TXT': 16,
    'AAAA': 28,
    'LOC': 29,
    'RRSIG': 46,
    'DNSKEY': 48,
    'ANY': 255
    }

def flatten(aray):
    result = "0x"
    for char in aray:
        result += char
    return result

def hex_of(num, length=1):
    theformat = "%02x"
    for i in range(2, length):
        format += "%02x"
    return (theformat % num).upper()
    
def flush(last=False):
    global step, group, hexstring, maskstring
    mask = ""
    if hexstring == []:
        return
    if (step % 4) != 0:
        # TODO: there is a bug here. If this (len(qname) modulo 4 ==
        # 1) - for instance ab.fr - *and* it is the last chunk of
        # filtering data *and* if the packet is shorter than that (it
        # can happen, if EDNS0 is not used), it will not match. u32
        # always operate on 4-bytes chunks :-( In practice,
        # amplification attacks use EDNS0 so it is not a too serious
        # problem. Otherwise, we will need to backtrack and change the
        # offset field to match the last four bytes. TODO
        for i in range(0, 4-(step%4)):
            hexstring.append("00")
            maskstring.append("00")
    if maskstring != ["00", "00", "00", "00"]: # Small optimisation
        mask = "&0x" 
        if (step % 4) == 0:
            for i in range(0, 4):
                mask += maskstring[i]
        else:
            for i in range(0, step%4):
                mask += maskstring[i]
            for i in range(step%4, 4):
                mask += "00"
        if maskstring == ["FF", "FF", "FF", "FF"]: # Small optimisation
            mask = ""
        sys.stdout.write("0>>22&0x3C@%i%s=%s" % (20+(group*4), mask,
                                                 flatten(hexstring)))
        if not last:
            sys.stdout.write("&&")
    hexstring = []
    maskstring = []
    group += 1
    
# Defaults
fqdn = None
querytype = None
bufsize = None
try:
    optlist, args = getopt.getopt (sys.argv[1:], "n:t:s:h",
                               ["qname=", "qtype=", "bufsize="])
    for option, value in optlist:
        if option == "--help" or option == "-h":
            usage()
            sys.exit(0)
        elif option == "--qname" or option == "-n":
            fqdn = value
        elif option == "--qtype" or option == "-t":
            querytype = types[value]
        elif option == "--bufsize" or option == "-s":
            bufsize = int(value)
        else:
            # Should never occur, it is trapped by getopt
            print >>sys.stderr, "Unknown option %s" % option
            usage()
            sys.exit(1)
except getopt.error, reason:
    usage(reason)
    sys.exit(1)
if len(args) != 0:
    usage()
    sys.exit(1)
if fqdn is None:
    usage("qname is mandatory (we cannot know the position of the other fields, otherwise)")
    sys.exit(1)
fqdn = string.upper(fqdn)
  
step = 0
group = 0
for label in fqdn.split('.'):
    if not label:
        break
    step += 1
    hexstring.append("%02x" % len(label))
    maskstring.append("FF")
    if (step % 4) == 0:
        flush()
    for char in label:
        step += 1
        hexstring.append("%02x" % ord(char))
        if ord(char) >= ord('A') and ord(char) <= ord('Z'):
            maskstring.append("DF") # Ignore the case bit for letters (to make the rule case-insensitive)
        else:
            maskstring.append("FF")
        if (step % 4) == 0:
            flush()
# Append the root
hexstring.append("00")
maskstring.append("FF")
step += 1
if querytype is None and bufsize is None:
    flush(last=True)
else:
    if (step % 4) == 0:
        flush()

if querytype is not None:
    hexstring.append("00")
    maskstring.append("FF")
    step += 1
    if (step % 4) == 0:
        flush()
    hexstring.append(hex_of(querytype))
    maskstring.append("FF")
    step += 1
    if (step % 4) == 0:
        flush(bufsize is None)
elif bufsize is not None:
    for i in range(0, 2): 
        hexstring.append("00")
        maskstring.append("00")
        step += 1
        if (step % 4) == 0:
            flush()

if bufsize is not None:
    # The class (we ignore it)
    for i in range(0, 2): 
        hexstring.append("00")
        maskstring.append("00")
        step += 1
        if (step % 4) == 0:
            flush()
    for nibble in "00", "00", "29": # Indicates the OPT pseudo Resource Record
        hexstring.append(nibble)
        maskstring.append("FF") 
        step += 1
        if (step % 4) == 0:
            flush()
    size_str = hex_of(bufsize, 2)
    hexstring.append(size_str[0:2])
    maskstring.append("FF") 
    step += 1
    if (step % 4) == 0:
        flush()
    hexstring.append(size_str[2:4])
    maskstring.append("FF") 
    step += 1

flush(last=True)
