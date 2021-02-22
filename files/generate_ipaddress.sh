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
	if echo ${devList} | grep -q "${1} UP"
	then
		ip address show dev ${1} | grep -Po '(?<=inet )((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])/([1-9]|[1-2][0-9]|3[0-2])(?= )'
	elif echo "${devList}" | grep -q "^${1} DOWN$"
	then
		echo "DOWN"
	else
		echo "MISSING"
	fi
	}

function modIP {
	operation=${1}
	ip_address=${2}
	device=$(echo "${3}" | cut -f 1 -d ":")
	device_full=${3}
	if [ "${device}" = "LAN" -o "${device}" = "WAN" ]
	then
		devicetype="${device}"
		eval device=\"\$dev${device}\"
		eval netIP=\"\$ip${devicetype}\"
	elif [ "${device}" = "${devLAN}" ]
	then
		devicetype="LAN"
		netIP="${ipLAN}"
	elif [ "${device}" = "${devWLAN}" ]
	then
		devicetype="WLAN"
		netIP="${ipWLAN}"
	fi

	if [ "${operation}" = "add" ]
	then
		if ! echo "${netIP}" | grep -q "${ip_address}"
		then
			echo "ip address add ${ip_address} dev ${device_full}"
			echo "arp -d ${ip_address}"
		fi
	elif [ "${operation}" = "del" ]
	then
		if echo "${netIP}" | grep -q "${ip_address}"
		then
			echo "ip address del ${ip_address} dev ${device}"
		fi
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
		eval netDev=\"\$dev${devActive}\"
		echo "${netDev}"
	else
		echo "NONE"
	fi
	}

function delInctiveIP {
	for device in LAN WLAN;
	do
		if [ "${devActive}" != "${device}" ]
		then
			eval netDev=\"\$dev${device}\"
			eval netIP=\"\$ip${device}\"
			if echo "${netIP}" | grep -q "${ipFull}"
			then
				modIP del ${ipFull} ${netDev}
			fi
		fi
	done
	}

function getLastOctett {
	eval net_prefix=\"\$ip${devActive}_prefix\"
	eval netIP=\"\$ip${devActive}\"
	echo "${netIP}" | grep "^${net_prefix}" | cut -f 4 -d "." 
	}

devList="$(getDev)"
devActive=$(leadingDevice)
ipLAN="$(getIP ${devLAN})"
ipWLAN="$(getIP ${devWLAN})"

echo "devActive=${devActive}"

if echo "${ipGlobal_prefix}" | grep -Po '^((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])$'
then
	ipFull="${ipGlobal_prefix}"
else
	ipFull="${ipGlobal_prefix}$(getLastOctett)"
fi

devLANcount=1
devWLANcount=1

if [ "${ipserveNet}" != "" -a "${ipserveNet}" != "NONE" ]
then
	if [ "${ipLAN}" != "DOWN" -o "${ipLAN}" != "MISSING" ]
	then
		modIP add ${ipserveNet} ${devLAN}:${devLANcount}
		devLANcount=$( expr ${devLANcount} + 1 )
	else
		modIP del ${ipserveNet} ${devLAN}
	fi
fi

if [ "${devActive}" = "LAN" ]
then
	delInctiveIP
	modIP add ${ipFull} $(leadingDeviceName):${devLANcount}
elif [ "${devActive}" = "WLAN" ]
then
	delInctiveIP
	modIP add ${ipFull} $(leadingDeviceName):${devWLANcount}
	fi