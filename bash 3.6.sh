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
#3.6 Configure Network Time Protocol (NTP)

printf "\n\e[1mAttempting to configure Network Time Protocol(NTP)\e[0m\n"

if grep '^restrict default' /etc/ntp.conf | grep "restrict default kod nomodify notrap nopeer noquery" &&  grep '^restrict -6 default' /etc/ntp.conf | grep "restrict -6 default kod nomodify notrap nopeer noquery" >/dev/null ; then
	printf "\e[32mDefaults are already restricted.\e[0m\n"
else
	printf "\e[34mAttempting to restrict defaults\e[0m\n"
	echo "restrict default kod nomodify notrap nopeer noquery" >> /etc/ntp.conf
	echo "restrict -6 default kod nomodify notrap nopeer noquery" >> /etc/ntp.conf
	printf "\e[32mDefaults are restricted.\e[0m\n"
fi

if grep "^server" /etc/ntp.conf >/dev/null ; then
	printf "\e[32mThere is at least one NTP server specified.\e[0m\n"
else
	printf "\e[34mThere is no NTP server. Adding server 10.10.10.10.\n"
	echo "server 10.10.10.10" >> /etc/ntp.conf
	printf "\e[32mServer 10.10.10.10 added.\e[0m\n"
	
fi

if `grep "ntp:ntp" /etc/sysconfig/ntpd | grep 'OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid"'`>/dev/null ; then
	printf "\e[32mOptions configured.\e[0m\n"
else
	printf "\e[34mOptions not configured. Attempting to configure...\e[0m\n"
	echo 'OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid"'>> /etc/sysconfig/ntpd
fi


if grep "^restrict default" /etc/ntp.conf >/dev/null && grep "^restrict -6 default" /etc/ntp.conf >/dev/null && grep "^server" /etc/ntp.conf >/dev/null && grep "ntp:ntp" /etc/sysconfig/ntpd >/dev/null ; then
	printf "\e[32mNTP fully configured.\e[0m\n"
else
	printf "\e[31mNTP is not fully configured.\e[0m\n"
fi

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.

read -n 1 -s
kill -9 $PPID
