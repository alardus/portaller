import os
os.popen('/usr/bin/python /var/www/portaller/tools/snistat.py -y >> /var/www/portaller/tools/snistat.data')
os.popen('/var/www/portaller/tools/gplot.pl -type jpg -title "DAU" -name "Portaller Active Users" -onecolumn /var/www/portaller/tools/snistat.data')
os.popen('/bin/mv /tmp/gplot.jpg /var/www/portaller/static/img')
os.popen('/usr/bin/service uwsgi restart')
