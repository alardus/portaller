#!/bin/bash
rule='python ./generate-netfilter-u32-dns-rule.py --qname zing.zong.co.ua --qtype ANY'
iptables -A INPUT -p udp --dport 53 --match u32 --u32 "$rule" -j DROP
