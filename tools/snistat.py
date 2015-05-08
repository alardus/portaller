import getopt, sys, os

date = os.popen("date +%Y-%m-%d").read().strip()

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hy")
    except getopt.GetoptError as err:
        print(err)
        sys.exit(2)
    for o, a in opts:
        if o in ("-h"):
            print 'Try -y argument'
        elif o in ("-y"):
        	global date
        	date = os.popen('date --date yesterday +%Y-%m-%d').read().strip()
        else:
            assert False, "unhandled option"

if __name__ == "__main__":
    main()

with open('/tmp/sniproxy.log', 'r'):
	p = os.popen("cat /tmp/sniproxy.log | grep " + date + "| grep pandora | awk '{print $3}' | cut -d : -f 1 | uniq | wc -l").read()
	s = os.popen("cat /tmp/sniproxy.log | grep " + date + "| grep spotify | awk '{print $3}' | cut -d : -f 1 | uniq | wc -l").read()
	r = os.popen("cat /tmp/sniproxy.log | grep " + date + "| grep rdio | awk '{print $3}' | cut -d : -f 1 | uniq | wc -l").read()
	n = os.popen("cat /tmp/sniproxy.log | grep " + date + "| grep netflix | awk '{print $3}' | cut -d : -f 1 | uniq | wc -l").read()
	a = os.popen("cat /tmp/sniproxy.log | grep " + date + "| grep amazon | awk '{print $3}' | cut -d : -f 1 | uniq | wc -l").read()

	print "Date "+date+'\n', "pandora "+p, "spotify "+s, "rdio "+r, "netflix "+n, "amazon "+a
	print int(p)+int(s)+int(r)+int(n)+int(a)
