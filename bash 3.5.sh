#!/bin/bash

#######################

reset

if [ "$EUID" -ne 0 ] ; then
	printf "\e[31mPlease run as root!\n"
	printf "Press any key to exit\e[0m\n"
	read -n 1 -s
	exit
fi

if [ -e /etc/redhat-release ] ; then
	printf "\e[1mRunning Scan for "
	printf "$(cat /etc/redhat-release)"
	printf "\e[0m\n"
else
	printf "\e[31m\e[1mYou are not on a Red Hat System!\n"
	printf "Press any key to exit\e[0m\n"
	read -n 1 -s
	kill -9 $PPID
fi

function ctrl_C() {
	kill -9 $PPID	
}

function ctrl_Z() {
	kill -9 $PPID
}

trap ctrl_C INT
trap ctrl_Z 2 20

######################
#3.5 Remove DHCP Server

printf "\n\e[1mAttempting to disable DHCPD if exists.\e[0m\n"
if systemctl is-active dhcpd | grep "active" >/dev/null && systemctl is-enabled dhcpd | grep "enabled" >/dev/null ; then
	printf "\e[31mDHCPD is not disabled. Attempting to disable now.\e[0m\n"
	systemctl stop dhcpd
	systemctl disable dhcpd
	printf "\e[32mDHCPD is now disabled.\e[0m\n"
elif systemctl is-active dhcpd | grep "inactive" >/dev/null && systemctl is-enabled dhcpd | grep "disabled" >/dev/null ; then
	printf "\e[32mDHCPD is already disabled.\e[0m\n"
else
	printf "\e[32mDHCPD is not installed.\e[0m\n"
fi

printf "\n\e[34mAttempting to remove any existing dhcp files.\e[0m\n"
	yum -y erase dhcp
	
	printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.

read -n 1 -s
kill -9 $PPID
