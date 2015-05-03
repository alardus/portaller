import os
date = os.popen("date +%Y-%m-%d").read().strip()
#date = '2015-03-31'
with open('/tmp/sniproxy.log', 'r'):
	p = os.popen("cat /tmp/sniproxy.log | grep " + date + "| grep pandora | awk '{print $3}' | cut -d : -f 1 | uniq | wc -l").read()
	s = os.popen("cat /tmp/sniproxy.log | grep " + date + "| grep spotify | awk '{print $3}' | cut -d : -f 1 | uniq | wc -l").read()
	r = os.popen("cat /tmp/sniproxy.log | grep " + date + "| grep rdio | awk '{print $3}' | cut -d : -f 1 | uniq | wc -l").read()
	n = os.popen("cat /tmp/sniproxy.log | grep " + date + "| grep netflix | awk '{print $3}' | cut -d : -f 1 | uniq | wc -l").read()
	a = os.popen("cat /tmp/sniproxy.log | grep " + date + "| grep amazon | awk '{print $3}' | cut -d : -f 1 | uniq | wc -l").read()

	print "Date "+date+'\n', "pandora "+p, "spotify "+s, "rdio "+r, "netflix "+n, "amazon "+a
	print int(p)+int(s)+int(r)+int(n)+int(a)
