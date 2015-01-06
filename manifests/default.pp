# We need to order provision commands [ https://docs.puppetlabs.com/learning/ordering.html ] 
Exec['update_pkgs_index']->
Package['curl'] ->
    Package['postgresql-9.3'] ->
    Package['libexpat1-dev'] ->
    Package['libpq-dev'] ->
Exec['install_cpanm']->
    Exec['install_cpanm_dbi']->
    Exec['install_cpanm_dbd_pg']->
    Exec['install_cpanm_date_simple']->
    Exec['install_cpanm_mail_sender']->
    Exec['install_cpanm_email_valid']->
    Exec['install_cpanm_pg_explain']->
    Exec['install_cpanm_mojolicious']->
Exec['createuser']->
    Exec['createdb']->
    Exec['psql_create']->
    Exec['psql_patch_1']->
    Exec['psql_patch_2']->
    Exec['psql_patch_3']->
    Exec['psql_grant']->
    Exec['run_daemon']


package { 'curl': # required by cpanminus installation
    ensure => installed
}

package { 'postgresql-9.3':
    ensure => installed
}

package { 'libexpat1-dev': # required by XML::Parser
    ensure => installed
}

package { 'libpq-dev': # required by DBD::Pg
    ensure => installed
}

Exec {
    path => [
       '/usr/local/bin',
       '/usr/bin',
       '/bin'],
    logoutput => true,
}

# FIXME: only debian-based systems are supported.
exec { 'update_pkgs_index': command => 'apt-get update' }

exec { 'install_cpanm':             command => 'curl -L http://cpanmin.us | perl - --self-upgrade' }
exec { 'install_cpanm_dbi':         command => 'cpanm --notest DBI' }
exec { 'install_cpanm_dbd_pg':      command => 'cpanm --notest DBD::Pg' }
exec { 'install_cpanm_date_simple': command => 'cpanm --notest Date::Simple' }
exec { 'install_cpanm_mail_sender': command => 'cpanm --notest Mail::Sender' }
exec { 'install_cpanm_email_valid': command => 'cpanm --notest Email::Valid' }
exec { 'install_cpanm_pg_explain':  command => 'cpanm --notest Pg::Explain', timeout => 600 }
exec { 'install_cpanm_mojolicious': command => 'cpanm --notest Mojolicious' }

exec { 'createuser': command => 'sudo -u postgres psql -c "create role explaind with login password \'explaind\'"' }
exec { 'createdb':   command => 'sudo -u postgres createdb -E utf8 -O explaind explaind' }

# FIXME: path to sql-files should be relative or parameter-based.
exec { 'psql_create':  command => 'sudo -u postgres psql -d explaind < /vagrant/sql/create.sql' }

# FIXME: load through sort | xargs
exec { 'psql_patch_1': command => 'sudo -u postgres psql -d explaind < /vagrant/sql/patch-001.sql' }
exec { 'psql_patch_2': command => 'sudo -u postgres psql -d explaind < /vagrant/sql/patch-002.sql' }
exec { 'psql_patch_3': command => 'sudo -u postgres psql -d explaind < /vagrant/sql/patch-003.sql' }
exec { 'psql_grant':   command => 'sudo -u postgres psql -d explaind -c "grant all on plans, users to explaind;"' }

exec { 'run_daemon':   command => 'hypnotoad /vagrant/explain.pl > /dev/null 2> /dev/null &' }



package { 'nginx':
    ensure => installed
}

file { '/etc/nginx/conf.d/explaind.conf':
    owner   => 'root',
    group   => 'root',
    content => '
server {
    listen 80;
    server_name explain.depesz.loc;

    location / {
        proxy_pass http://127.0.0.1:12004;
    }
}
',
    notify  => Service['nginx'],
    require => Package['nginx'],
}

service { 'nginx':
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => true,
}
