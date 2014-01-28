#!/usr/bin/env bash

# app database details
DB_NAME="sample"
DB_USER="application"
DB_PASS="password"

# root database password
DB_ROOT_PASS="password"

# add 512mb swap
dd if=/dev/zero of=/swapfile bs=1024 count=512k
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
chown root:root /swapfile
chmod 0600 /swapfile

# dotdeb sources
echo "deb http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list
echo "deb-src http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list
echo "deb http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list
echo "deb-src http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list
wget http://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg
apt-get update

# essentials
apt-get install -Vy vim git

# mysql
export DEBIAN_FRONTEND=noninteractive
apt-get install -Vy mysql-client mysql-server
mysql_install_db

# create app database
mysql -u root -e "CREATE DATABASE $DB_NAME;"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost IDENTIFIED BY '$DB_PASS';"

# allow remote root access
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY '$DB_ROOT_PASS';"

# change root mysql password
mysqladmin -u root password $DB_ROOT_PASS

# php
apt-get install -Vy php5 php5-common php5-cli php5-fpm php5-mysqlnd php5-mcrypt php5-xdebug
sed -i "s/^\;date\.timezone.*$/date\.timezone = \"Europe\/London\"/g" /etc/php5/fpm/php.ini
sed -i "s/^\expose_php.*$/expose_php = Off/g" /etc/php5/fpm/php.ini
sed -i "s/^\upload_max_filesize.*$/upload_max_filesize = 10M/g" /etc/php5/fpm/php.ini
sed -i "s/^\post_max_size.*$/post_max_size = 10M/g" /etc/php5/fpm/php.ini
sed -i "s/^\; max_input_vars.*$/max_input_vars = 5000/g" /etc/php5/fpm/php.ini
sed -i "s/^\display_errors.*$/display_errors = On/g" /etc/php5/fpm/php.ini
sed -i "s/^\display_startup_errors.*$/display_startup_errors = On/g" /etc/php5/fpm/php.ini

# php-fpm
update-rc.d php5-fpm defaults
/etc/init.d/php5-fpm start

# lighttpd
apt-get -Vy install lighttpd
rm /etc/lighttpd/lighttpd.conf
ln -fs /vagrant/lighttpd.conf /etc/lighttpd/lighttpd.conf
/etc/init.d/lighttpd restart

# aliases
echo "alias v=\"clear;cd /vagrant\"" >> /home/vagrant/.bashrc
echo "alias c=\"clear\"" >> /home/vagrant/.bashrc
echo "alias l=\"ls -lah\"" >> /home/vagrant/.bashrc
echo "alias ..=\"cd ..\"" >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

exit 0