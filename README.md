explain.depesz.com
==================

Setup
==================

1) Mojolicious

You have to have Mojolicious installed on your server.  Mojolicious is a web framework for Perl.
http://mojolicio.us/

Installation can be accomplished with one command line:

    curl -L cpanmin.us | perl - -n Mojolicious
    
See the "Installation" section at http://mojolicio.us/ for details.

2) Perl Dependencies:
You will need the following packages installed in your version of Perl:

    DBD::Pg
    Date::Simple
    Mail::Sender
    Pg::Explain
    Email::Valid
    

Install the above packages using "cpan" then "i Date::Simple", "i Maill::Sender" &etc.

3) PostgreSQL

A) Create a new database "explain".  This will be were the explain server will store the "users" 
and "plans" tables in the default schema "public".

B) Run SQL scripts.  Log into postgres as postgres. Switch to the "explain" database.  
Execute the SQL scripts located in the "sql" directory in the following order:

    \i create.sql
    \i patch-001.sql
    \i patch-002.sql
    
The "create.sql" will create tables in the explain database "public" schema, i.e. "plans" and "users".

B) Create a user role.  I use "explaind" [explain daemon] and remember to provides it a password and then configure
the explain.json file to reflect this new role and password.

C) Grant all rights to the tables in "explain" to your role "explaind":

     grant all on plans, users to explaind;

D) modify  /etc/postgresql-9.3/pg_hba.conf so that it has the server as "127.0.0.1"

    local   all             all             127.0.0.1               trust
    
If you do not want to alter  /etc/postgresql-9.3/pg_hba.conf, then you might be able 
to modify the explain.json.dsn setting to specify the name of the value i
n the server column from your /etc/postgresql-9.3/pg_hba.conf file, e.g. "localhost".  This 
alternative approach has not been tested.  It would be desirable to install this project with
the minimal amount of configuration changes, so I encourage someone to come up with a solution
that removes this step "D".

4) Alter configuration file explain.json making sure you have the correct values for your database connection.
See companion documentation file explain-json-notes.txt

5) Shell

The explain server runs on port 3000.  Make sure port 3000 is available and not in use by another process.
You may have to specify a different port, e.g. 3200.  I do not know where you do that, probably in Mojolicious.

In the trunk directory for this project, run in a shell:

     ./explain daemon
     
Then access the web page http://localhost:3000

6) when you access the web page, remember to login and create an account for yourself so that your explain plans 
will be associated with your account.
