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
#3.2 Remove X Window System	

printf "\n\e[1mAttempting to remove X Window System.\e[0m\n"
yum -y remove xorg-x11-server-common
printf "\n\e[1mChanging boot target.\e[0m\n"
cd /etc/systemd/system/
unlink default.target
ln -s /usr/lib/systemd/system/multi-user.target default.target
if [ ls -l /etc/systemd/system/default.target | grep graphical.target ] ; then
	printf "\e[31mX Windows System is the default user.\e[0m\n"
else
	printf "\e[32mX Windows System is not the default user.\e[0m\n"
fi

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.

read -n 1 -s
kill -9 $PPID
