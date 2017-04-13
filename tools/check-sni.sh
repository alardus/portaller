#!/bin/bash
pid=`ps aux | grep -v grep | grep sniproxy | awk '{print $2}'` 
#echo $pid

if [ "$pid" != '' ]; then 
	exit 0
else 
	`/usr/sbin/sniproxy`
#	rm /var/tmp/sniproxy.pid
fi

