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
#2.6
printf "\e[1mDisable chargen-dgram\e[0m\n"
if yum list xinetd | grep "Available Packages" >/dev/null ; then
	printf "\e[32mAlready removed Chargen-Dgram from removing Xinetd.\e[0m\n"
elif yum list xinetd | grep "Installed Packages" && chkconfig --list chargen-dgram | grep "on" >/dev/null ; then
	printf "\e[31m Chargen-Dgram enabled. Attempting to disable.\e[0m\n"
	result=`chkconfig chargen-dgram off`
else 
	printf "\e[32mChargen-Dgram is already disabled.\e[0m\n"
fi

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.
read -n 1 -s
kill -9 $PPID