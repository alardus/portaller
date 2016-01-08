import os
os.popen('/usr/bin/python /var/www/portaller/tools/snistat.py -y')
os.popen('/var/www/portaller/tools/gplot.pl  -type jpg -title "DAU" -onecolumn -name "Amazon Video" amazon.data -name Netflix netflix.data -name HBO hbo.data -name Pandora pandora.data -name Spotify spotify.data -name Overall snistat.data')
os.popen('/bin/mv /tmp/gplot.jpg /var/www/portaller/static/img')
os.popen('/usr/bin/service uwsgi restart')
