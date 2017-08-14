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


#Part 1

#create new hard disk first
printf "\e[1mCreating new hard disk\e[0m\n"
printf "\e[1m\nPLEASE CREATE A NEW HARD DISK WITH 20GB. This will create /dev/sdb.\e[0m\n"
parted -s /dev/sdb mklabel msdos #makes an MSDOS partition table 
parted -s /dev/sdb mkpart primary ext2 0% 100% #make primary partition, from size 0% to 100%
parted -s /dev/sdb set 1 lvm on #make partition 1 of /dev/sdb an lvm partition
pvcreate /dev/sdb1
vgextend rhel /dev/sdb1



#1.1-1.4 /tmp
printf "\e[1mCreating separate /tmp partition and setting options.\e[0m\n"
if lvcreate -l 10%VG -n tmp rhel ; then
	echo "/dev/rhel/tmp	/tmp	ext4	nodev,nosuid,noexec	0 0" >> /etc/fstab
	printf "\e[32mExecuted.\e[0m\n"
else
	printf "\e[31mUnable to create /tmp!\e[0m\n"
fi


#1.5 /var
printf "\e[1mCreating separate /var partition.\e[0m\n"
if lvcreate -l 10%VG -n var rhel ; then
	echo "/dev/rhel/var	/var	ext4	defaults	0 0" >> /etc/fstab
	printf "\e[32mExecuted.\e[0m\n"
else
	printf "\e[31mUnable to create /var!\e[0m\n"
fi


#1.6 bind mount
printf "\e[1mBinding mount.\e[0m\n"
printf "/tmp /var/tmp none bind 0 0" >> /etc/fstab
mount --bind /tmp /var/tmp
printf "\e[32mExecuted.\e[0m\n"


#1.7 /var/log
printf "\e[1mCreating separate partition for /var/log\e[0m\n"
if lvcreate -l 10%VG -n log rhel ; then
	ln -s /log /var/log
	echo "/dev/rhel/log	/var/log	ext4	defaults	0 0" >> /etc/fstab
	printf "\e[32mExecuted.\e[0m\n"
else
	printf "\e[31mUnable to create /var/log! Manual configuration required.\e[0m\n"
fi


#1.8 /var/log/audit
printf "\e[1mCreating separate partition for /var/log/audit\e[0m\n"
if lvcreate -l 10%VG -n audit rhel ; then
	ln -s /audit /var/log/audit
	echo "/dev/rhel/audit	/var/log/audit	ext4	defaults	0 0" >> /etc/fstab
	printf "\e[32mExecuted.\e[0m\n"
else
	printf "\e[31mUnable to create /var/log/audit! Manual configuration required.\e[0m\n"
fi


#1.9-1.10 /home
printf "\e[1mCreating separate partition for /home and setting options.\e[0m\n"
if lvcreate -l 10%VG -n home rhel ; then
	echo "/dev/rhel/home	/home	ext4	nodev	0 0" >> /etc/fstab
	printf "\e[32mExecuted.\e[0m\n"
else
	printf "\e[31mUnable to create /home!\e[0m\n"
fi


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


#1.14 sticky bit
printf "\e[1mSetting Sticky Bit on All World-Writable Directories\e[0m\n"
if df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \(-perm -0002 -a ! -perm -1000 \) 2> /dev/null ; then
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \(-perm -0002 -a ! -perm -1000 \) 2> /dev/null | xargs chmod o+t
printf "\e[32mExecuted.\e[0m\n"
else
printf "\e[31mUnable to set sticky bit.\e[0m\n"
fi

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


#Verify the package integrity
echo "Verify Package Integrity Using RPM"
echo "Might have unexpected discrepancies identified in the audit step"


#Part 2

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

#2.2
printf "\e[1mRemove rsh Server and Clients\e[0m\n"
if yum list rsh-server | grep "Available Packages" && yum list rsh | grep "Available Packages" >/dev/null ; then
printf "\e[32mRSH server and clients not installed\e[0m\n"
else
printf "\e[34mDisabling server and clients\e[0m\n"
result=`yum -y erase rsh-server`
result=`yum -y erase rsh`
printf "\e[32mExecuted.\e[0m\n" 
fi

#2.3
printf "\e[1mRemove NIS Server & Clients\e[0m\n"
if yum list ypserv | grep "Available Packages" && yum list ypbind | grep "Available Packages" >/dev/null ; then
printf "\e[32mNIS Server and Clients not installed\e[0m\n"
else
printf "\e[34mDisabling server and clients\e[0m\n"
result=`yum -y erase ypserv`
result=`yum -y erase ypbind`
printf "\e[32mExecuted.\e[0m\n" 
fi

#2.4
printf "\e[1mRemove tftp Server and Clients\e[0m\n"
if yum list tftp-server | grep "Available Packages" && yum list tftp | grep "Available Packages" >/dev/null ; then
printf "\e[32mtftp Server and Clients not installed\e[0m\n"
else
printf "\e[34mDisabling server\e[0m\n"
result=`yum -y erase tftp`
result=`yum -y erase tftp-server`
printf "\e[32mExecuted.\e[0m\n" 
fi

#2.5
printf "\e[1mRemove xinetd\e[0m\n"
if yum list xinetd | grep "Installed Packages" >/dev/null ; then
	printf "\e[31mXinetd installed. Attempting to remove.\e[0m\n"
	result=`yum -y erase xinetd`
	printf "\e[32mExecuted\e[0m\n"
else
printf "\e[32mXinetd is not installed.\e[0m\n"
fi

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

#2.7
printf "\e[1mDisable chargen-stream\e[0m\n"
if yum list xinetd | grep "Available Packages" >/dev/null ; then
	printf "\e[32mAlready removed Chargen-stream from removing Xinetd.\e[0m\n"
elif yum list xinetd | grep "Installed Packages" && chkconfig --list chargen-stream | grep "on" >/dev/null ; then
	printf "\e[31m Chargen-stream enabled. Attempting to disable.\e[0m\n"
	result=`chkconfig chargen-stream off`
else 
	printf "\e[32mChargen-stream is already disabled.\e[0m\n"
fi

#2.8
printf "\e[1mDisable daytime-dgram/daytime-stream\e[0m\n"
if yum list xinetd | grep "Available Packages" >/dev/null ; then
	printf "\e[32mAlready removed daytime-dgram and daytime-stream from removing Xinetd.\e[0m\n"
elif yum list xinetd | grep "Installed Packages" && chkconfig --list daytime-dgram | grep "on" && chkconfig --list daytime-stream | grep "on" >/dev/null ; then
	printf "\e[31m Daytime-dgram and Daytime-stream enabled. Attempting to disable.\e[0m\n"
	result=`chkconfig daytime-dgram off`
	result=`chkconfig daytime-stream off`
elif yum list xinetd | grep "Installed Packages" && chkconfig --list daytime-dgram | grep "off" && chkconfig --list daytime-stream | grep "off" >/dev/null ; then
	printf "\e[32mDaytime-dgram and daytime-stream are disabled.\e[0m\n"
else
	printf "\e[34m One is not disabled. Attempting to disable.\e[0m\n"
	result=`chkconfig daytime-dgram off`
	result=`chkconfig daytime-stream off`
	printf "\e[32mDisabled.\e[0m\n"
fi

#2.9
printf "\e[1mDisable echo-dgram/echo-stream\e[0m\n"
if yum list xinetd | grep "Available Packages" >/dev/null ; then
	printf "\e[32mAlready removed echo-dgram and echo-stream from removing Xinetd.\e[0m\n"
elif yum list xinetd | grep "Installed Packages" && chkconfig --list echo-dgram | grep "on" && chkconfig --list echo-stream | grep "on" >/dev/null ; then
	printf "\e[31m Echo-dgram and Echo-stream enabled. Attempting to disable.\e[0m\n"
	result=`chkconfig echo-dgram off`
	result=`chkconfig echo-stream off`
elif yum list xinetd | grep "Installed Packages" && chkconfig --list echo-dgram | grep "off" && chkconfig --list echo-stream | grep "off" >/dev/null ; then
	printf "\e[32mEcho-dgram and Echo-stream are disabled.\e[0m\n"
else
	printf "\e[34m One is not disabled. Attempting to disable.\e[0m\n"
	result=`chkconfig echo-dgram off`
	result=`chkconfig echo-stream off`
	printf "\e[32mDisabled.\e[0m\n"
fi

#2.10
printf "\e[1mDisable tcpmux-server\e[0m\n"
if yum list xinetd | grep "Available Packages" >/dev/null ; then
	printf "\e[32mAlready removed Tcpmux-server from removing Xinetd.\e[0m\n"
elif yum list xinetd | grep "Installed Packages" && chkconfig --list tcpmux-server | grep "on" >/dev/null ; then
	printf "\e[31m Tcpmux-server enabled. Attempting to disable.\e[0m\n"
	result=`chkconfig tcpmux-server off`
else 
	printf "\e[32mTcpmux-server is already disabled.\e[0m\n"
fi

#Part 3

#3.1 Daemon umask
printf "\n\e[1mAttempting to set default umask as 027.\e[0m\n"
if grep ^umask /etc/sysconfig/init | grep "027" >/dev/null ; then
	printf "\e[32mDefault umask is 027.\e[0m\n"
else
	printf "\e[34mChanging default umask to 027.\e[0m\n"
	echo "umask 027" >> /etc/sysconfig/init
	printf "\e[32mDefault umask is 027.\e[0m\n"
fi

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

#3.4 Disable CUPS Print Server
printf "\n\e[1mAttempting to disable CUPS Print Server.\e[0m\n"

if systemctl is-active cups | grep "active" >/dev/null && systemctl is-enabled cups | grep "enabled" >/dev/null ; then
	printf "\e[34mCUPS is not disabled. Attempting to disable now.\e[0m\n"
	systemctl stop cups
	systemctl disable cups
	printf "\e[32mCUPS is now disabled.\e[0m\n"
elif systemctl is-active cups | grep "inactive" >/dev/null && systemctl is-enabled cups | grep "disabled" >/dev/null ; then
	printf "\e[32mCUPS Print Server is already disabled.\e[0m\n"
elif systemctl is-active cups | grep "active" >/dev/null && systemctl is-enabled cups | grep "disabled" >/dev/null ; then
	printf "\e[32mCUPS is disabled.\e[0m\n"	
	systemctl stop cups
fi


#3.5 Remove DHCP Server
printf "\n\e[1mAttempting to disable DHCPD if exists.\e[0m\n"
if systemctl is-active dhcpd | grep "active" >/dev/null && systemctl is-enabled dhcpd | grep "enabled" >/dev/null ; then
	printf "\e[31mDHCPD is not disabled. Attempting to disable now.\e[0m\n"
	systemctl stop dhcpd
	systemctl disable dhcpd
	printf "\e[32mDHCPD is now disabled.\e[0m\n"
elif systemctl is-active dhcpd | grep "inactive" >/dev/null && systemctl is-enabled dhcpd | grep "disabled" >/dev/null ; then
	printf "\e[32mDHCPD is already disabled.\e[0m\n"
else
	printf "\e[32mDHCPD is not installed.\e[0m\n"
fi

printf "\n\e[34mAttempting to remove any existing dhcp files.\e[0m\n"
	yum -y erase dhcp

#3.6 Configure Network Time Protocol (NTP)
printf "\n\e[1mAttempting to configure Network Time Protocol(NTP)\e[0m\n"

if grep '^restrict default' /etc/ntp.conf | grep "restrict default kod nomodify notrap nopeer noquery" &&  grep '^restrict -6 default' /etc/ntp.conf | grep "restrict -6 default kod nomodify notrap nopeer noquery" >/dev/null ; then
	printf "\e[32mDefaults are already restricted.\e[0m\n"
else
	printf "\e[34mAttempting to restrict defaults\e[0m\n"
	echo "restrict default kod nomodify notrap nopeer noquery" >> /etc/ntp.conf
	echo "restrict -6 default kod nomodify notrap nopeer noquery" >> /etc/ntp.conf
	printf "\e[32mDefaults are restricted.\e[0m\n"
fi

if grep "^server" /etc/ntp.conf >/dev/null ; then
	printf "\e[32mThere is at least one NTP server specified.\e[0m\n"
else
	printf "\e[34mThere is no NTP server. Adding server 10.10.10.10.\n"
	echo "server 10.10.10.10" >> /etc/ntp.conf
	printf "\e[32mServer 10.10.10.10 added.\e[0m\n"
	
fi

if `grep "ntp:ntp" /etc/sysconfig/ntpd | grep 'OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid"'`>/dev/null ; then
	printf "\e[32mOptions configured.\e[0m\n"
else
	printf "\e[34mOptions not configured. Attempting to configure...\e[0m\n"
	echo 'OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid"'>> /etc/sysconfig/ntpd
fi


if grep "^restrict default" /etc/ntp.conf >/dev/null && grep "^restrict -6 default" /etc/ntp.conf >/dev/null && grep "^server" /etc/ntp.conf >/dev/null && grep "ntp:ntp" /etc/sysconfig/ntpd >/dev/null ; then
	printf "\e[32mNTP fully configured.\e[0m\n"
else
	printf "\e[31mNTP is not fully configured.\e[0m\n"
fi

#3.7 Remove LDAP
printf "\n\e[1mAttempting to remove Lightweight Directory Access Protocol(LDAP)if existing.\e[0m\n"
yum -y erase openldap-clients
yum -y erase openldap-servers
printf "\e[32mLDAP not installed.\e[0m\n"


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

#3.9 Remove DNS, FTP, HTTP, HTTP-Proxy, SNMP
printf "\n\e[1mAttempting to disable DNS\e[0m\n"
if systemctl is-enabled named | grep "enabled" >/dev/null && systemctl is-active named | grep "active" >/dev/null; then
	printf "\e[31mDNS is not disabled. Attempting to disable.\e[0m\n"
	systemctl stop named
	systemctl disable named
	printf "\e[32mDNS is now disabled.\e[0m\n"
elif systemctl is-active named | grep "inactive" >/dev/null && systemctl is-enabled named | grep "disabled" >/dev/null ; then
	printf "\e[32mDNS is already disabled.\e[0m\n"
else
	printf "\e[32mDNS is not installed.\e[0m\n"
fi


printf "\n\e[1mAttempting to remove FTP\e[0m\n"
yum -y erase ftp
printf "\e[32mFTP not installed.\e[0m\n"


printf "\n\e[1mAttempting to remove HTTP\e[0m\n"
yum -y erase httpd
printf "\e[32mHTTPD not installed.\e[0m\n"


printf "\n\e[1mAttempting to remove HTTP Proxy Service\e[0m\n"
yum -y erase squid
printf "\e[32mHTTP Proxy Server not installed.\e[0m\n"


printf "\n\e[1mAttempting to remove SNMP\e[0m\n"
yum -y erase net-snmp
printf "\e[32mSNMP Service not installed.\e[0m\n"

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
read -n 1 -s
kill -9 $PPID