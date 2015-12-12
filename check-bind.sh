#!/bin/bash
pid=`ps aux | grep -v grep | grep named | awk '{print $2}'`
#echo $pid

if [ "$pid" != '' ]; then
	exit 0
else
	`/etc/init.d/bind9 restart`
 #	rm /var/tmp/sniproxy.pid
fi
