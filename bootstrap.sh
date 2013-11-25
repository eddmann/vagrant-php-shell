#!/usr/bin/env bash

if [[ -n $1 && $1 = "apache" ]]; then
    APACHE=1
fi

# app database details
DB_NAME="sample"
DB_USER="application"
DB_PASS="password"

# root database password
DB_ROOT_PASS="password"

# essentials
yum install -y vim git

# set the localtime
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime

# disable firewall for development
/etc/init.d/iptables stop
chkconfig iptables off

# remi and epel repositories for latest releases
rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

# mysql
yum --enablerepo=remi install -y mysql mysql-server
chkconfig --levels 235 mysqld on
/etc/init.d/mysqld start

# create app database
mysql -u root -e "CREATE DATABASE $DB_NAME;"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost IDENTIFIED BY '$DB_PASS';"

# allow remote root access
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY '$DB_ROOT_PASS';"

# change root mysql password
mysqladmin -u root password $DB_ROOT_PASS

# php
yum --enablerepo=remi-php55,remi install -y \
    php php-fpm php-common php-cli php-opcache php-pecl-xdebug \
    php-pear php-mysqlnd php-pdo php-sqlite php-gd php-mbstring \
    php-mcrypt php-xml
sed -i "s/^\;date\.timezone.*$/date\.timezone = \"Europe\/London\"/g" /etc/php.ini
sed -i "s/^\expose_php.*$/expose_php = Off/g" /etc/php.ini
sed -i "s/^\upload_max_filesize.*$/upload_max_filesize = 10M/g" /etc/php.ini
sed -i "s/^\post_max_size.*$/post_max_size = 10M/g" /etc/php.ini
sed -i "s/^\; max_input_vars.*$/max_input_vars = 5000/g" /etc/php.ini
sed -i "s/^\display_errors.*$/display_errors = On/g" /etc/php.ini
sed -i "s/^\display_startup_errors.*$/display_startup_errors = On/g" /etc/php.ini

# php-fpm
chkconfig --levels 235 php-fpm on
sed -i "s/^\listen.*$/listen = \/tmp\/php5-fpm.sock/g" /etc/php-fpm.d/www.conf
mkdir /usr/lib/cgi-bin/
/etc/init.d/php-fpm start

if [ -z $APACHE ]; then

# nginx
echo "[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/6/x86_64/
gpgcheck=0
enabled=1" > /etc/yum.repos.d/nginx.repo
yum install -y nginx
rm /etc/nginx/conf.d/default.conf
ln -fs /vagrant/nginx.conf /etc/nginx/conf.d/nginx.conf # use provided
chkconfig --levels 235 nginx on
/etc/init.d/nginx start

else

# apache
yum install -y httpd
rm -rf /var/www/html
ln -fs /vagrant /var/www/html
sed -i "s/^\s*DocumentRoot.*$/DocumentRoot \"\/var\/www\/html\/public\"/g" /etc/httpd/conf/httpd.conf
sed -i "s/^\s*#ServerName.*$/ServerName development:80/g" /etc/httpd/conf/httpd.conf
sed -i "s/^\s*AllowOverride.*$/AllowOverride All/g" /etc/httpd/conf/httpd.conf
sed -i "s/^\s*#EnableSendfile.*$/EnableSendfile Off/g" /etc/httpd/conf/httpd.conf
sed -i "s/^\s*DirectoryIndex.*$/DirectoryIndex index.php index.html/g" /etc/httpd/conf/httpd.conf
chkconfig --levels 235 httpd on

# mod_fastcgi
rpm -Uvh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
yum --enablerepo=rpmforge-extras install -y mod_fastcgi
sed -i "s/^/#/" /etc/httpd/conf.d/php.conf # comment-out all php.conf
sed -i "s/^\FastCgiWrapper.*$/FastCgiWrapper Off/g" /etc/httpd/conf.d/fastcgi.conf
echo "<IfModule mod_fastcgi.c>
AddHandler php5-fcgi .php
Action php5-fcgi /php5-fcgi
Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -socket /tmp/php5-fpm.sock -pass-header Authorization
</IfModule>" >> /etc/httpd/conf.d/fastcgi.conf

/etc/init.d/httpd start

fi

# mailcatcher
yum install -y ruby rubygems ruby-devel
gem install i18n mailcatcher
mailcatcher --http-ip=0.0.0.0
sed -i "s/^\sendmail_path.*$/sendmail_path = \/usr\/bin\/env catchmail/g" /etc/php.ini
/etc/init.d/php-fpm restart

# composer
cd /home/vagrant
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# aliases
echo "alias v=\"clear;cd /vagrant\"" >> /home/vagrant/.bashrc
echo "alias c=\"clear\"" >> /home/vagrant/.bashrc
echo "alias l=\"ls -lah\"" >> /home/vagrant/.bashrc
echo "alias ..=\"cd ..\"" >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

exit 0