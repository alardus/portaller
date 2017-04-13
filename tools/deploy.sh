#!/bin/sh

# preparing
cd /tmp/portaller
echo "Workdir /tmp/portaller"

# /usr/bin/git clone https://github.com/alardus/portaller.git
/usr/bin/git pull https://github.com/alardus/portaller.git
echo "Pulling last changes"

# cd /tmp/portaller
# echo "Workdir /tmp/portaller"

# deploy
cp /etc/sniproxy.conf /etc/sniproxy.conf.save
cp /etc/bind/zones.override /etc/bind/zones.override.save
echo "Backup created"

cp -R ./configs/etc/bind/zones.override /etc/bind/
echo "New 'zones' installed"

cp -R ./configs/etc/sniproxy.conf /etc/sniproxy.conf
echo "New 'sniproxy' installed"

echo "Restarting BIND..."
/usr/bin/service bind9 restart

echo "Restarting SNI..."
cd ./tools
./snirestart.sh
