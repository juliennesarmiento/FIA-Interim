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
#1.11-1.13 removable media partitions
printf "\e[1mSetting options for Removable Media Partitions\e[0m\n"
if grep -e cdrom -e floppy /etc/fstab > /dev/null; then
	printf "\e[34mChanging settings of Removable Media Partitions.\e[0m\n"
	sed -i '/cdrom/ s/defaults/nodev,nosuid,noexec/g' /etc/fstab
	sed -i '/floppy/ s/defaults/nodev,nosuid,noexec/g' /etc/fstab
	printf "\e[32mExecuted.\e[0m\n"
else
	printf "\e[32mNo cdrom or floppy found!\e[0m\n"
fi

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.
read -n 1 -s
kill -9 $PPID