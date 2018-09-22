#! /bin/bash

# Assumptions:
#	- language: en_US
#	- location: US Eastern Timezone

packages='git vim'

read -p "New user: " $user
home="/home/$user"

# ROOT SCRIPTS
if [[ `whoami` == "root" ]]; then
	# create new user
	adduser --home $home --shell /bin/bash $user
	usermod -aG sudo $user

	# raspi-config
	hostname pi
	sed -i -e 's/en_GB/#en_GB/g' /etc/local.gen
	sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/local.gen
	locale-gen en_US.UTF-8
	sed -i -e 's/en_GB/en_US/g' /etc/default/locale
	echo 'LC_ALL=en.US.UTF-8' >> /etc/default/locale
	update-locale en_US.UTF-8
	cp /usr/share/zoneinfo/America/New_York /etc/localtime
	localectl set-x11-keymap us

	# install packages
	apt-get update
	apt-get upgrade -y
	apt-get install -y $packages

	# enable ssh
	systemctl enable ssh
	systemctl start ssh

fi

