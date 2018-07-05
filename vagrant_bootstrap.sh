#!/bin/bash

export PGDATA="/etc/postgresql/10/main"
export APP_USER="explain"
export APP_PASS="explain"

# Set username in explain.json
sed -i "s/\"username\" : \"explain\"/\"username\" : \"${APP_USER}\"/" /vagrant/explain.json
sed -i "s/\"password\" : \"explain\"/\"password\" : \"${APP_PASS}\"/" /vagrant/explain.json

# Install dependencies
curl -s -L cpanmin.us | perl - -n Mojolicious
apt-get -y -qq install wget ca-certificates cpanminus libmojolicious-perl libmail-sender-perl libdate-simple-perl libemail-valid-perl libxml-simple-perl libdbd-pg-perl libxml-simple-perl
cpanm -q Pg::Explain

# Install Postgres
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get -y -qq update
sudo apt-get -y -qq upgrade
sudo apt-get -y -qq install postgresql-10
sed -i -e "s/peer/trust/" ${PGDATA}/pg_hba.conf
sudo -u postgres psql -tc "select pg_reload_conf()"

# Create database
createdb -U postgres explain

# Create user
psql -qU postgres explain -c "CREATE USER ${APP_USER} WITH PASSWORD '${APP_PASS}'"

# Apply patches
psql -q -f /vagrant/sql/create.sql -U postgres explain
for i in `seq -f "%03g" 1 10`
do
  psql -q -f /vagrant/sql/patch-${i}.sql -U postgres explain
done

# Apply grants
psql -qU postgres explain -c "GRANT ALL ON plans, users TO ${APP_USER}"
psql -qU postgres explain -c "GRANT ALL ON SCHEMA plans TO ${APP_USER}"
for x in `echo {0..9} {A..Z} {a..z}`
do
  psql -qU postgres explain -c "GRANT ALL PRIVILEGES ON plans.\"part_${x}\" TO ${APP_USER}"
done

# Done
echo "Your Vagrant box is all set up.  Use 'vagrant ssh' to log in, then call '/vagrant/explain.pl daemon' to start the service"
