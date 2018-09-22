#! /bin/bash

# Assumptions:
#	- language: en_US
#	- location: US Eastern Timezone

packages='git stow tmux vim'

# exit immediately if any command fails
set -e

if [[ `whoami` == 'root' ]]; then
	# create new user
	read -p "New user: " user
	home="/home/$user"
	adduser --home $home --shell /bin/bash $user
	usermod -aG sudo $user

	# raspi-config
	hostname pi
	sed -i -e 's/en_GB/#en_GB/g' /etc/locale.gen
	sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
	locale-gen en_US.UTF-8
	sed -i -e 's/en_GB/en_US/g' /etc/default/locale
	echo 'LC_ALL=en_US.UTF-8' >> /etc/default/locale
	update-locale en_US.UTF-8
	cp /usr/share/zoneinfo/America/New_York /etc/localtime
	localectl set-x11-keymap us

	# enable ssh
	systemctl enable ssh
	systemctl start ssh

	# setup user script
	cp init.sh $home/init.sh
	echo 'if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then' >> $home/.bashrc
	echo '	source ~/init.sh' >> $home/.bashrc
	echo 'fi' >> $home/.bashrc

	echo "Finished root setup.  Connect pi to router and SSH into pi to finish setup."
	echo "Don't forget to setup port forwarding on the router."
	read -p 'Press ENTER to shutdown pi.'
	shutdown -h now

elif [[ `whoami` == 'pi' ]]; then
	echo "You must run this script as root."
else
	# sshd setup
	user=`whoami`
	echo 'On dev machine(s), run ssh-copy-id pi'
	read -p "Press ENTER to lockdown sshd"
	sudo sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication no' /etc/ssh/sshd_config
	sudo systemctl restart ssh

	sudo userdel pi

	# install packages
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo pt-get install -y $packages
	
	# todo pull in dotfiles, authfiles, install python dependencies

	#pushd ~/.dotfiles
	#stow *
	#popd

	# install python dependencies
	#fp="/tmp/fp.txt"
	#for file in `find ~/.dotfiles -name 'requirements.txt'`
	#do
	#	cat $file >> $fp
	#done
	#pip3 install -r $fp

	curl -sSL https://install.pi-hole.net | bash
	curl -sSL https://install.pivpn.io | bash

	lip=`ifconfig eth0 | grep inet | xargs | cut -d' ' -f2`
	# remove init script
	sed -i -e "s/source ~\/init.sh/# SSH USER/g" ~/.bashrc
	echo
	echo "RASPBERRY PI SERVER SETUP IS COMPLETE!!"
	echo "DON'T FORGET MANUAL INSTALLATION STEPS:"
	echo
	echo "Router Configuration"
	echo " - Port forwarding for radicale (5232)"
	echo " - Port forwarding for pivpn (1194)"
	echo " - Set default DNS to $lip"
	echo
	echo "iPhone Configuration"
	echo " - contacts @ <ip>:5232/$user/contacts"
	echo " - calendar @ <ip>:5232/$user/calendar"

fi
