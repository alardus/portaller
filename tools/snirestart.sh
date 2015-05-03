#!/bin/sh
pid=`/bin/ps aux | /bin/grep sniproxy | /bin/grep daemon | /usr/bin/awk {'print $2'}`
echo $pid

echo "Killing sniproxy"
`/bin/kill -9 $pid`

echo "Wating for 3 sec"
sleep 3

/usr/sbin/sniproxy
