#!/bin/bash

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

#Part 1

#create new hard disk first

printf "\e[1mCreating new hard disk\e[0m\n"
printf "\e[1m\nPLEASE CREATE A NEW HARD DISK WITH 20GB. This will create /dev/sdb.\e[0m\n"
parted -s /dev/sdb mklabel msdos #makes an MSDOS partition table 
parted -s /dev/sdb mkpart primary ext2 0% 100% #make primary partition, from size 0% to 100%
parted -s /dev/sdb set 1 lvm on #make partition 1 of /dev/sdb an lvm partition
pvcreate /dev/sdb1
vgextend rhel /dev/sdb1

printf "\e[32mCompleted!\n"
printf "Press any key to exit\e[0m\n"

#This kills the process, please remove if not needed.

read -n 1 -s
kill -9 $PPID
