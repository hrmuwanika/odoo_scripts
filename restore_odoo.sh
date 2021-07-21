#!/bin/bash

# Setting Up Automatic Reset an Odoo Instance for Demonstration purposes
# mkdir -p /opt/script && cd /opt/script
# wget https://raw.githubusercontent.com/hrmuwanika/odoo_scripts/main/restore_odoo.sh 
# sudo chmod +x restore_odoo.sh

# To backup every 3 hours
# sudo crontab -e
# 0 */3 * * * /opt/script/restore_odoo.sh  

# vars
BACKUP_DIR=~/odoo_backups
ODOO_DATABASE=odoodb1
ODOO_USER=odoo

# location of the extracted create a backup directory
cd ${BACKUP_DIR}

# add the databases, users and grant permissions to them
systemctl restart postgresql
sudo -u postgres psql -c "DROP DATABASE $ODOO_DATABASE";
sudo -u postgres psql -c "CREATE DATABASE $ODOO_DATABASE";
sudo -u postgres psql -c "CREATE ROLE $ODOO_USER WITH SUPERUSER LOGIN PASSWORD '$ODOO_USER'";
sudo -u postgres psql -c "ALTER DATABASE $ODOO_DATABASE OWNER TO $ODOO_USER";
sudo -u postgres psql $ODOO_DATABASE < dump.sql
systemctl restart postgresql

# Filestore location        
mkdir -p /odoo/.local/share/Odoo/filestore/$ODOO_DATABASE            
cp -rf filestore/* /odoo/.local/share/Odoo/filestore/$ODOO_DATABASE 
chown -R odoo:odoo /odoo/.local/share/Odoo/filestore/$ODOO_DATABASE/*
