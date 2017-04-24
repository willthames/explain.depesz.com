# Unfortunately there is no way to automatically detect current project directory
if $use_vagrant {
    $PROJECT_DIR = '/vagrant'
} else {
    fail('Replace this line with correct $PROJECT_DIR value assignment.')
}


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
    Exec['psql_apply_patches']->
    Exec['psql_grant']->
    Exec['run_daemon']


Exec {
    path => [
       '/usr/local/bin',
       '/usr/bin',
       '/bin'],
    logoutput => true,
}


exec { 'update_pkgs_index': command => 'apt-get update' }

exec { 'install_cpanm':             command => 'curl -L http://cpanmin.us | perl - --self-upgrade' }
exec { 'install_cpanm_dbi':         command => 'cpanm --notest DBI' }
exec { 'install_cpanm_dbd_pg':      command => 'cpanm --notest DBD::Pg' }
exec { 'install_cpanm_date_simple': command => 'cpanm --notest Date::Simple' }
exec { 'install_cpanm_mail_sender': command => 'cpanm --notest Mail::Sender' }
exec { 'install_cpanm_email_valid': command => 'cpanm --notest Email::Valid' }
exec { 'install_cpanm_pg_explain':  command => 'cpanm --notest Pg::Explain', timeout => 600 } # Takes about 450-500 secs.
exec { 'install_cpanm_mojolicious': command => 'cpanm --notest Mojolicious' }

exec { 'createuser': command => 'sudo -u postgres psql -c "create role explain with login password \'explain\'"' }
exec { 'createdb':   command => 'sudo -u postgres createdb -E utf8 -O explain explain' }

exec { 'psql_create':
    command => sprintf("sudo -u postgres psql -d explain < %s/sql/create.sql", $PROJECT_DIR)
}
exec { 'psql_apply_patches':
    command => sprintf("ls -1 %s/sql/patch-???.sql | sort | xargs -n1 sudo -u postgres psql -d explain -q -f", $PROJECT_DIR)
}
exec { 'psql_grant':
    command => 'sudo -u postgres psql -d explain -c "GRANT USAGE ON SCHEMA public, plans TO explain; GRANT ALL ON ALL TABLES IN SCHEMA public,plans TO explain;"'
}

exec { 'run_daemon': command => sprintf("hypnotoad %s/explain.pl > /dev/null 2> /dev/null &", $PROJECT_DIR) }


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

package { 'nginx':
    ensure => installed
}


file { '/etc/nginx/conf.d/explain.conf':
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

file { '/etc/nginx/sites-enabled/default':
    ensure => "absent",
    purge => true,
    notify  => Service['nginx'],
    require => Package['nginx'],
}


service { 'nginx':
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => true,
}
