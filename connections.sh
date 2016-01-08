#!/bin/bash
/bin/netstat -atW | grep EST | awk {'print $5'} | cut -d : -f 1 | sort | uniq | grep -v pandora | grep -v spotify | grep -v amazon | grep -v netflix | grep -v portaller | wc -l > /var/www/portaller/connections.txt

uptime | awk -F'[a-z]:' '{ print $2}' >> /var/www/portaller/connections.txt
ps aux | grep sniproxy | grep daemon | awk '{print $2}' >> /var/www/portaller/connections.txt
