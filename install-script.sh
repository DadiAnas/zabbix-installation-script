#set Zabbix_user_password=zabbix
set DBHost=localhost
export DBHost


# Install Zabbix repository 
sudo rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
sudo dnf clean all 
# Install Zabbix server, frontend, agent 
sudo dnf install zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-agent sed -y

# install postgresql
sudo dnf module list postgresql
sudo dnf module enable postgresql:12 -y
sudo dnf install postgresql-server -y
sudo postgresql-setup --initdb
# Give permissions to postgresdb
sudo sed -i 's/local   all             all                                     peer/local   all             all                                     trust/' /var/lib/pgsql/data/pg_hba.conf
sudo sed -i 's/host    all             all             127.0.0.1\/32            ident/host    all             all             127.0.0.1\/32            trust/' /var/lib/pgsql/data/pg_hba.conf
sudo sed -i 's/host    all             all             ::1\/128                 ident/host    all             all             ::1\/128                 trust/' /var/lib/pgsql/data/pg_hba.conf
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Create initial database
sudo systemctl start postgresql
sudo -u postgres createuser zabbix
sudo -u postgres createdb -O zabbix zabbix
sudo zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix 
sudo systemctl restart postgresql

# config zabbix-server host and password
sudo sed -i 's/# DBHost=localhost/# DBhost=localhost\n\nDBHost=localhost/' /etc/zabbix/zabbix_server.conf
sudo sed -i 's/# DBPassword=/# DBPassword=\n\nDBPassword=zabbix/' /etc/zabbix/zabbix_server.conf


# SELinux configuration
sudo setsebool -P httpd_can_connect_zabbix on
sudo setsebool -P httpd_can_network_connect_db on
#change selinux from enforce to permissive
sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/'  /etc/selinux/config
# config timezone php
sudo sed -i 's/; php_value\[date\.timezone\] = Europe\/Riga/php_value\[date\.timezone\] = Africa\/Casablanca/' /etc/php-fpm.d/zabbix.conf
# open port 80 for apache
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --reload
# start apache server
sudo systemctl start httpd
# Start Zabbix server and agent processes 
sudo systemctl restart zabbix-server zabbix-agent httpd php-fpm
sudo systemctl enable zabbix-server zabbix-agent httpd php-fpm
