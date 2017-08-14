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
#3.1 Daemon umask

printf "\n\e[1mAttempting to set default umask as 027.\e[0m\n"
if grep ^umask /etc/sysconfig/init | grep "027" >/dev/null ; then
	printf "\e[32mDefault umask is 027.\e[0m\n"
else
	printf "\e[34mChanging default umask to 027.\e[0m\n"
	echo "umask 027" >> /etc/sysconfig/init
	printf "\e[32mDefault umask is 027.\e[0m\n"
fi

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.

read -n 1 -s
kill -9 $PPID
