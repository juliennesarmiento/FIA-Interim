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

#3.10
printf "\n\e[1mConfiguring Mail Transfer Agent for Local-Only Mode.\e[0m\n"
if netstat -an | grep LIST | grep ":25[[:space:]]" ; then
	printf "\e[32mMTA is listening on 127.0.0.1.\e[0m\n"
else
	printf "\e[31mMTA is not listening on 127.0.0.1.\e[0m\n"
fi

if grep "inet_interfaces = localhost" /etc/postfix/main.cf ; then
  	sed -i '/receiving mail/ s/inet_interfaces = localhost/inet_interfaces = localhost/g' /etc/postfix/main.cf
	printf "\e[32mLine already exists. Replacing line.\e[0m\n"
else
  	sed '/#inet_interfaces = $myhostname, localhost/a inet_interfaces = localhost' /etc/postfix/main.cf
	printf "\e[32mLine added.\e[0m\n"
fi
	
systemctl restart postfix

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.
read -n 1 -s
kill -9 $PPID
