#! /bin/bash

ipLAN_prefix="192.168.96."
ipWLAN_prefix="192.168.97."
ipGlobal_prefix="192.168.98."
ipserveNet="172.16.1.4/16"

devLAN="eth0"
devWLAN="wlan0"

function getDev {
	ip -br addr show | while read LINE; do echo ${LINE} | cut -f 2,1 -d " "; done | grep -v "UNKNOWN$"
	}

function getIP {
	if echo "${devList}" | grep -q "${1} UP"
	then
		ip address show dev ${1} | grep -Po '(?<=inet )((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])/([1-9]|[1-2][0-9]|3[0-2])(?= )'
	elif echo "${devList}" | grep -q "${1} DOWN"
	then
		echo "DOWN"
	else
		echo "MISSING"
	fi
	}

function leadingDevice {
	returnString="NONE"
	for device in WLAN LAN;
	do
		eval netDev=\"\$dev${device}\"
		eval netIP=\"\$ip${device}\"

		if [ "${netIP}" != "DOWN" -o "${netIP}" != "MISSING" ]
		then
			returnString="${device}"
		fi
	done
	echo "${returnString}"
	}

function leadingDeviceName {
	if [ "${devActive}" = "LAN" -o "${devActive}" = "WLAN" ]
	then
		eval netDev=\"\$dev${device}\"
		echo "${netDev}"
	else
		echo "NONE"
	fi
	}

function delActiveGlobal {
	for device in LAN WLAN;
	do
		if [ "${devActive}" != "${device}" ]
		then
			eval netDev=\"\$dev${device}\"
			eval netIP=\"\$ip${device}\"
			if echo "netIP" | grep -q "${ipFull}"
			then
				echo "ip address del ${ipFull} dev $(netDev)"
			fi
		fi
	done
	}

function getLastOctett {
	eval net_prefix=\"\$ip${devActive}_prefix\"
	eval netIP=\"\$ip${devActive}\"
	echo "getLastOctett: ${devActive}"
	echo "${netIP}" | grep "^${net_prefix}" | cut -f 4 -d "." 
	}

devList="$(getDev)"
devActive=$(leadingDevice)
ipLAN="$(getIP ${devLAN})"
ipWLAN="$(getIP ${devWLAN})"

if echo "${ipGlobal_prefix}" | grep -Po '^((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])$'
then
	ipFull="${ipGlobal_prefix}"
else
	ipFull="${ipGlobal_prefix}$(getLastOctett)"
fi

echo "devList: ${devList}" >&2
echo "devActive: ${devActive}" >&2
echo "ipLAN: ${ipLAN}" >&2
echo "ipWLAN: ${ipWLAN}" >&2
echo "ipFull: ${ipFull}" >&2

devLANcount=1
devWLANcount=1

if [ "${ipserveNet}" != "" -a "${ipserveNet}" != "NONE" ]
then
	if [ "${ipLAN}" != "DOWN" -o "${ipLAN}" != "MISSING" ]
	then
		echo "ip address add ${ipserveNet} dev ${devLAN}:${devLANcount}"
		devLANcount=$( expr ${devLANcount} + 1 )
	else
		echo "ip address del ${ipserveNet} dev ${devLAN}"
	fi
fi

if [ "${devActive}" = "LAN" ]
then
	echo "ip address add ${ipFull} dev $(leadingDeviceName):${devLANcount}"
	echo "arp -d ${ipFull}"
elif [ "${devActive}" = "WLAN" ]
then
	echo "ip address add ${ipFull} dev $(leadingDeviceName):${devWLANcount}"
	echo "arp -d ${ipFull}"
	fi