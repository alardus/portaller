#!/bin/sh

# Local interface (usually it's a bridge of wired and WiFi interfaces)
inIF='br-lan'
# External interface (to ISP)
extIF='eth0.2'

# Pseudo-addresses to catch non-SNI request and redirect them to upstream proxy
# The IP-s are added to local interface
sADDR='192.168.44.3' # 301 302 303
sADDR_MASK='29'
# IP-address of upstream proxy (must be inside the US)
dADDR='107.170.15.247' # portaller.com

# 'Mask' of the upsteam's port. The specific port is a concat. of the mask and the number
dPORT0='443'

# Pathes
I='/usr/sbin/iptables'
IP='/usr/sbin/ip'

# Mode of operation (add / remove)
IPT_ACTION="A"
IP_ACTION="add"

[ "x${1}" == "x--delete" ] && \
	IPT_ACTION="D" && \
	IP_ACTION="del"

HOSTS="api-global.netflix.com uiboot.netflix.com secure.netflix.com"

for ID in `seq 1 3`; do
	#echo "Setting up pseudo-address ${sADDR}${ID} on ${inIF}"
	$IP addr ${IP_ACTION} ${sADDR}${ID}/${sADDR_MASK} dev ${inIF} > /dev/null 2>&1

	#echo "Configuring DNAT-redirection from the IP to ${dPORT0}${ID}"
	$I -t nat -${IPT_ACTION} PREROUTING ! -i ${extIF} -p tcp -d ${sADDR}${ID} --dport 443 -j DNAT --to-destination ${dADDR}:${dPORT0}${ID} > /dev/null 2>&1

	#echo "Configuring firewall..."
	$I -t filter -${IPT_ACTION} FORWARD ! -i ${extIF} -p tcp -d ${dADDR} --dport ${dPORT0}${ID} -j ACCEPT > /dev/null 2>&1

	echo "[${IP_ACTION}] ${sADDR}${ID}:443 -> ${dADDR}:${dPORT0}${ID}"
done

if [ "x${IP_ACTION}" == "xadd" ]; then
	ID=1
	echo "Now please add the following lines to your dnsmasq configuration, 'config dnsmasq' section (/etc/config/dhcp)"
	for H in ${HOSTS}; do
		echo "list address '/${H}/${sADDR}${ID}'"
		let ID=${ID}+1
	done
fi
