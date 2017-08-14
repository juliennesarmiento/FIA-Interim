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
#3.8 Disable NFS and RPC
printf "\n\e[1mAttempting to disable NFS and RPC\e[0m\n"

if systemctl is-enabled nfs-lock | grep "enabled" >/dev/null && systemctl is-enabled nfs-secure | grep "enabled" >/dev/null && systemctl is-enabled rpcbind | grep "enabled" >/dev/null && systemctl is-enabled nfs-idmap | grep "enabled" >/dev/null && systemctl is-enabled nfs-secure-server | grep "enabled" ; then
	printf "\e[31mNFS and RPC are not disabled. Attempting to disable\e[0m\n"
	systemctl disable nfs-lock
	systemctl disable nfs-secure
	systemctl disable rpcbind
	systemctl disable nfs-idmap
	systemctl disable nfs-secure-server
	printf "\e[32mNFS and RPC now disabled.\e[0m\n"
elif systemctl is-enabled nfs-lock | grep "disabled" >/dev/null && systemctl is-enabled nfs-secure | grep "disabled" >/dev/null && systemctl is-enabled rpcbind | grep "disabled" >/dev/null && systemctl is-enabled nfs-idmap | grep "disabled" >/dev/null && systemctl is-enabled nfs-secure-server | grep "disabled" ; then
	printf "\e[32mNFS and RPC already disabled.\e[0m\n"
else
	systemctl disable nfs-lock
	systemctl disable nfs-secure
	systemctl disable rpcbind
	systemctl disable nfs-idmap
	systemctl disable nfs-secure-server
	printf "\e[32mNFS and RPC disabled.\e[0m\n"
fi

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.
read -n 1 -s
kill -9 $PPID