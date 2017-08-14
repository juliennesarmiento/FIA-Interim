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
#3.3 Disable Avahi Server

printf "\n\e[1mAttempting to disable Avahi Server.\e[0m\n"
if systemctl is-active avahi-daemon | grep "active" >/dev/null && systemctl is-enabled avahi-daemon | grep "enabled" >/dev/null ; then
	printf "\e[34mAvahi Server is not disabled. Attempting to disable now.\e[0m\n"
	systemctl disable avahi-daemon.service avahi-daemon.socket
	systemctl stop avahi-daemon.service avahi-daemon.socket
	printf "\e[32mAvahi Server is now disabled.\e[0m\n"
elif systemctl is-active avahi-daemon | grep "inactive" >/dev/null && systemctl is-enabled avahi-daemon | grep "disabled" >/dev/null ; then
	printf "\e[32mAvahi Server is already disabled.\e[0m\n"
fi

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.

read -n 1 -s
kill -9 $PPID
