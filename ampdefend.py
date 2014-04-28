import os, syslog
base = []
host = []

check = os.popen("cat /var/log/named/named.log | grep ANY | grep queries | awk '{print $9}'").readlines()
for i in check:
	if i not in host:
		host.append(i)

with open('/var/www/portaller/hostbase.txt', 'r') as hostbase:
	for i in hostbase:
		base.append(i)

for i in host:
	if i not in base:
		rule = os.popen("/var/www/portaller/generate-netfilter-u32-dns-rule.py --qname " + i.strip() + " --qtype ANY").read()
		os.system("/sbin/iptables -A INPUT -p udp --dport 53 --match u32 --u32 '"+rule+"' -j DROP")
		with open('/var/www/portaller/hostbase.txt', 'a') as hostbase:
			hostbase.write(i)
		syslog.syslog(syslog.LOG_ERR, i.strip() + " was banned")
	else:
		pass
