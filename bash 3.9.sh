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
#3.9 Remove DNS, FTP, HTTP, HTTP-Proxy, SNMP
printf "\n\e[1mAttempting to disable DNS\e[0m\n"
if systemctl is-enabled named | grep "enabled" >/dev/null && systemctl is-active named | grep "active" >/dev/null; then
	printf "\e[31mDNS is not disabled. Attempting to disable.\e[0m\n"
	systemctl stop named
	systemctl disable named
	printf "\e[32mDNS is now disabled.\e[0m\n"
elif systemctl is-active named | grep "inactive" >/dev/null && systemctl is-enabled named | grep "disabled" >/dev/null ; then
	printf "\e[32mDNS is already disabled.\e[0m\n"
else
	printf "\e[32mDNS is not installed.\e[0m\n"
fi


printf "\n\e[1mAttempting to remove FTP\e[0m\n"
yum -y erase ftp
printf "\e[32mFTP not installed.\e[0m\n"


printf "\n\e[1mAttempting to remove HTTP\e[0m\n"
yum -y erase httpd
printf "\e[32mHTTPD not installed.\e[0m\n"


printf "\n\e[1mAttempting to remove HTTP Proxy Service\e[0m\n"
yum -y erase squid
printf "\e[32mHTTP Proxy Server not installed.\e[0m\n"


printf "\n\e[1mAttempting to remove SNMP\e[0m\n"
yum -y erase net-snmp
printf "\e[32mSNMP Service not installed.\e[0m\n"

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.
read -n 1 -s
kill -9 $PPID