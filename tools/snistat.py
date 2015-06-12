import getopt, sys, os

pandora_out = 'pandora.data'
spotify_out = 'spotify.data'
rdio_out = 'rdio.data'
netflix_out = 'netflix.data'
amazon_out = 'amazon.data'
hbo_out = 'hbo.data'
overall = 'snistat.data'

date = os.popen("date +%Y-%m-%d").read().strip()

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hyd")
    except getopt.GetoptError as err:
        print(err)
        sys.exit(2)
    for o, a in opts:
        if o in ("-h"):
            print 'Y R HERE'
            sys.exit()
        elif o in ("-y"):
                global date
                date = os.popen('date --date yesterday +%Y-%m-%d').read().strip()
        elif o in ("-d"):
                # global date
                date = sys.argv[2]
        else:
            assert False, "unhandled option"

if __name__ == "__main__":
    main()


# How many people use services?
# p = os.popen("cat /var/log/sniproxy.log | grep " + date + "| grep pandora | awk '{print $3}' | cut -d : -f 1 | sort | uniq | wc -l").read()
# s = os.popen("cat /var/log/sniproxy.log | grep " + date + "| grep spotify | awk '{print $3}' | cut -d : -f 1 | sort |uniq | wc -l").read()
# r = os.popen("cat /var/log/sniproxy.log | grep " + date + "| grep rdio | awk '{print $3}' | cut -d : -f 1 | sort | uniq | wc -l").read()
# n = os.popen("cat /var/log/sniproxy.log | grep " + date + "| grep netflix | awk '{print $3}' | cut -d : -f 1 | sort | uniq | wc -l").read()
# a = os.popen("cat /var/log/sniproxy.log | grep " + date + "| grep amazon | awk '{print $3}' | cut -d : -f 1 | sort | uniq | wc -l").read()
# h = os.popen("cat /var/log/sniproxy.log | grep " + date + "| grep hbo | awk '{print $3}' | cut -d : -f 1 | sort | uniq | wc -l").read()

# print "Date "+date+'\n', "pandora "+p, "spotify "+s, "rdio "+r, "netflix "+n, "amazon "+a, "hbo "+h
# print int(p)+int(s)+int(r)+int(n)+int(a)+int(h)


# DAU
seen = []
ip = []

log = os.popen("cat /var/log/sniproxy.log | grep " + date + " | awk '{print $3,$8}' | sed 's/:/ /g' |  awk '{print $1,$3}'").readlines()

for i in log:
    if i.split(' ')[0] not in ip:
        ip.append(i.split(' ')[0])
        seen.append(i)

pandora = 0
spotify = 0
rdio = 0
netflix = 0
amazon = 0
hbo = 0

for i in seen:
    if 'pandora' in i:
        pandora += 1
    elif 'spotify' in i:
        spotify += 1
    elif 'rdio' in i:
        rdio += 1
    elif 'netflix' in i:
        netflix += 1
    elif 'amazon' in i:
        amazon += 1
    elif 'hbo' in i:
        hbo += 1

# print "Date "+date+'\n', "pandora ", pandora, "spotify ", spotify, "rdio ", rdio, "netflix ", netflix, "amazon ", amazon, "hbo ", hbo

with open(pandora_out, 'a+') as fl:
    fl.write(str(pandora))
    fl.write('\n')

with open(spotify_out, 'a+') as fl:
    fl.write(str(spotify))
    fl.write('\n')

with open(rdio_out, 'a+') as fl:
    fl.write(str(rdio))
    fl.write('\n')

with open(netflix_out, 'a+') as fl:
    fl.write(str(netflix))
    fl.write('\n')

with open(amazon_out, 'a+') as fl:
    fl.write(str(amazon))
    fl.write('\n')

with open(hbo_out, 'a+') as fl:
    fl.write(str(hbo))
    fl.write('\n')

with open(overall, 'a+') as fl:
    fl.write(str(pandora+spotify+rdio+netflix+amazon+hbo))
    fl.write('\n')
