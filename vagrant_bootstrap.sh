#!/bin/bash

PGDATA="/etc/postgresql/9.3/main"

curl -s -L cpanmin.us | perl - -n Mojolicious
apt-get -y -qq install cpanminus libmojolicious-perl libmail-sender-perl libdate-simple-perl libemail-valid-perl libxml-simple-perl libdbd-pg-perl libxml-simple-perl
cpanm -q Pg::Explain
apt-get -y -qq install postgresql postgresql-contrib
sed -i -e "s/md5/trust/" -e "s/peer/trust/" ${PGDATA}/pg_hba.conf
sudo -u postgres psql -tc "select pg_reload_conf()"

createdb -U postgres explain
psql -qU postgres explain < /vagrant/sql/create.sql
psql -qU postgres explain < /vagrant/sql/patch-001.sql
psql -qU postgres explain < /vagrant/sql/patch-002.sql
psql -qU postgres explain -c "CREATE USER explain WITH PASSWORD 'explain'"
psql -qU postgres explain -c "GRANT ALL ON plans, users TO explain"
echo "Your Vagrant box is all set up.  Use 'vagrant ssh' to log in, then call '/vagrant/explain.pl daemon' to start the service"
