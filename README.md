explain.depesz.com
==================

Setup
==================

There are three ways to install your own copy:

1. Using Vagrant [ VirtualBox machine, fully automated ]
1. Calling `puppet apply`
1. Manually

First get the source code:

    git clone https://gitlab.com/depesz/explain.depesz.com.git

## Vagrant setup

*WARNING:*
The first call of `vagrant up` fetches a ~400MB vbox image from the Internet.

1. Call `vagrant up`

Point your browser on http://192.168.44.55 (or use `/etc/hosts` entry explain.depesz.loc)

## Puppet setup

1. Install puppet on your machine, e.g. Debian installation described [here](https://docs.puppetlabs.com/guides/install_puppet/install_debian_ubuntu.html).
1. Open `explain.pp` and fix line 5 with correct project dir value
1. Call `sudo puppet apply --logdest console explain.pp` on your working copy directory.

## Manual setup

### 1) Mojolicious
You have to have Mojolicious installed on your server.
Mojolicious is a web framework for Perl.
http://mojolicio.us/

Installation can be accomplished with one command line:

    curl -L cpanmin.us | perl - -n Mojolicious

See the `Installation` section at http://mojolicio.us/ for details.

### 2) Perl Dependencies:
You will need the following packages installed in your version of Perl:

    DBD::Pg
    Date::Simple
    Mail::Sender
    Pg::Explain
    Email::Valid


Install the above packages using `cpan` then `-i Date::Simple`, `-i Mail::Sender`, &etc.

Note that in case of most current Linux distributions, you can install most of
these from binary package repositories. For example, in case of Ubuntu and
Debian, you can:

    apt-get install libmojolicious-perl \
                    libmail-sender-perl \
                    libdate-simple-perl \
                    libemail-valid-perl \
                    libxml-simple-perl  \
                    libdbd-pg-perl

And then only add `Pg::Explain` via CPAN.

### 3) PostgreSQL
You'll need to have PostgreSQL installed in order to record all the explain
plans into history.  Consult the [PostgreSQL Wiki](https://wiki.postgresql.org/wiki/Detailed_installation_guides)
for more information

#### 3A) Create a new database `explain`
This will be were the explain server will store the `users` and `plans` tables
in the default schema `public`.

#### 3B) Run SQL scripts
Log in to the `explain` database and execute the SQL scripts located in this
project's `sql` directory in the following order:

    \i create.sql
    \i patch-001.sql
    \i patch-002.sql

The `create.sql` will create tables in the `explain` database `public` schema,
i.e. `plans` and `users`.

#### 3C) Create a user role
I use `explaind` [explain daemon], for example.  Remember to provide it a
password and then configure the `explain.json` file to reflect this new role and
password.

    CREATE USER explaind WITH PASSWORD 'explain';

#### 3D) Grant all rights to the tables in `explain` to your role:

    GRANT ALL ON plans, users TO explaind;

#### 3E) modify  `pg_hba.conf` so that it has the server as "127.0.0.1"

    local   all             all             127.0.0.1               trust

If you do not want to alter `pg_hba.conf`, then you might be able to modify the
`explain.json.dsn` setting to specify the name of the value in the server column
from your `pg_hba.conf` file, e.g. "localhost".  This alternative approach has
not been tested.  It would be desirable to install this project with the minimal
amount of configuration changes, so I encourage someone to come up with a
solution that removes this step "E".

### 4) Configure `explain.json`
Make sure you have the correct values for your database connection.
See companion documentation file `explain-json-notes.txt`

### 5) Shell
The explain server runs on port 3000.  Make sure port 3000 is available and not
in use by another process. You may have to specify a different port (e.g. 3200).
I do not know where you do that, probably in Mojolicious.

In the trunk directory for this project, run in a shell:

     ./explain.pl daemon

### 6) Browser
Then access the web page `http://localhost:3000`  When you access the web page,
remember to login and create an account for yourself so that your explain plans
will be associated with your account.
