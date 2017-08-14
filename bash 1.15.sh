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

#1.15 legacy filesystems

printf "\e[1mDisabling mounting of Legacy Filesystems.\e[0m\n"
printf "install cramfs /bin/true\n" > /etc/modprobe.d/CIS.conf
printf "install freevxfs /bin/true\n" >> /etc/modprobe.d/CIS.conf
printf "install jffs2 /bin/true\n" >> /etc/modprobe.d/CIS.conf
printf "install hfs /bin/true\n" >> /etc/modprobe.d/CIS.conf
printf "install hfsplus /bin/true\n" >> /etc/modprobe.d/CIS.conf
printf "install squashfs /bin/true\n" >> /etc/modprobe.d/CIS.conf
printf "install udf /bin/true\n" >> /etc/modprobe.d/CIS.conf
printf "\e[32mExecuted.\e[0m\n"

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.

read -n 1 -s
kill -9 $PPID
