#!/bin/bash

################################################################################
# Script for installing Odoo backend (PostgreSQL) on Ubuntu 20.04 LTS (could be used for other version too)
# Author: Henry Robert Muwanika
---------------------------------------------------------------
# Make a new file:
# sudo nano install_odoo_backend.sh
# Place this content in it and then make the file executable:
# sudo chmod +x install_odoo_backend.sh
# Execute the script to install Odoo:
# ./install_odoo_backend.sh
################################################################################

FRONTEND_IP=192.168.118.167
BACKEND_IP=192.168.118.168

#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#Port 22/Port 578/' /etc/ssh/sshd_config
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

sudo apt install -y fail2ban

#--------------------------------------------------
# UFW Firewall
#--------------------------------------------------
sudo apt install -y ufw 

sudo ufw allow 578/tcp
sudo ufw allow 5432//tcp
sudo ufw enable -y

#--------------------------------------------------
# Update Server
#--------------------------------------------------
sudo apt update 
sudo apt upgrade -y
sudo apt autoremove -y

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
sudo apt -y install gnupg gnupg2
sudo apt -y install vim bash-completion wget
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update && sudo apt upgrade -y
sudo apt install -y postgresql postgresql-client
sudo systemctl start postgresql && sudo systemctl enable postgresql

echo -e "\n=============== Creating the ODOO PostgreSQL User ========================="
sudo su - postgres -c "createuser -s odoo" 2> /dev/null || true

# Allow postgresql traffic between the frontend and the backend
echo -e "host    all             all            127.0.0.1/32            trust" >> /etc/postgresql/*/main/pg_hba.conf
echo -e "host    all             all            $FRONTEND_IP/32        trust" >> /etc/postgresql/*/main/pg_hba.conf

sed  -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost,$BACKEND_IP'/"  /etc/postgresql/*/main/postgresql.conf

iptables -A INPUT -p tcp -s $FRONTEND_IP/32 --dport 5432 -j ACCEPT

# Run this command if your using fail2ban
sed -i -r "s|(ignoreip = .*)|\1 $FRONTEND_IP/32|" /etc/fail2ban/jail.conf
systemctl restart fail2ban

sudo systemctl start postgresql
