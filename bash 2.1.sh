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
#2.1

printf "\e[1mRemove telnet Server & Clients\e[0m\n"
if yum list telnet-server | grep "Available Packages" && yum list telnet | grep "Available Packages" >/dev/null ; then
printf "\e[32mtelnet-server and clients not installed\e[0m\n"
else
printf "\e[34mDisabling server and clients\e[0m\n"
result=`yum -y erase telnet-server`
result=`yum -y erase telnet`
printf "\e[32mExecuted.\e[0m\n" 
fi

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.

read -n 1 -s
kill -9 $PPID
