#!/bin/bash

## ++   qubes-vpn-handler.sh   ++ ##
##
## Handles DNS address translation and link notification for Qubes VPN VMs.
## To use, set as 'up' and 'down' script with parameter in your openvpn config.
## Examples:
## up 'qubes-vpn-handler.sh test-up'  (for link testing in VPN VM)
## up 'qubes-vpn-handler.sh up'
## down 'qubes-vpn-handler.sh down'
##
## Adapting for other VPN clients: Simply replace the openvpn DHCP 'foreign_option_*'
## variables, or supply a 'vpn_dns' variable.

set -e

# Pop-up notification variables
SPID=$(pgrep -U user -f dconf-service)
dbus=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$SPID/environ|cut -d= -f2-)
export DBUS_SESSION_BUS_ADDRESS=$dbus

case "$1" in

test-up)

##  Use test-up parameter to test your basic VPN link before enabling qubes-firewall-user-script
##  (do NOT use beyond testing period). Type-in your nameserver address:
	cp -a /etc/resolv.conf /etc/resolv.vpnbak
	echo "nameserver TYPE-your-dns-address-here" >/etc/resolv.conf
	usr/lib/qubes/qubes-setup-dnat-to-ns
	su -c 'notify-send "$(hostname): LINK IS UP." --icon=network-idle' user
	exit 0

;;
up)
	# To override DHCP DNS, assign static DNS addresses with 'setenv vpn_dns' in openvpn config;
	# Format is 'X.X.X.X  Y.Y.Y.Y [...]' with quotes.
	if [[ -z $vpn_dns ]] ; then
		# Parses DHCP options from openvpn to set DNS address translation:
		for optionname in ${!foreign_option_*} ; do
			option="${!optionname}"
			unset fops; fops=($option)
			if [ ${fops[1]} == "DNS" ] ; then vpn_dns="$vpn_dns ${fops[2]}" ; fi
		done
	fi

	iptables -t nat -F PR-QBS
	if [[ -n $vpn_dns ]] ; then
		# Set DNS address translation in firewall:
		for addr in $vpn_dns; do
			iptables -t nat -A PR-QBS -i vif+ -p udp --dport 53 -j DNAT --to $addr
			iptables -t nat -A PR-QBS -i vif+ -p tcp --dport 53 -j DNAT --to $addr
		done
		su -c 'notify-send "$(hostname): LINK IS UP." --icon=network-idle' user
	else
		su -c 'notify-send "$(hostname): LINK UP, NO DNS!" --icon=dialog-error' user
	fi

	;;
down)
	iptables -t nat -F PR-QBS
	su -c 'notify-send "$(hostname): LINK IS DOWN !" --icon=dialog-error' user

	;;
esac
