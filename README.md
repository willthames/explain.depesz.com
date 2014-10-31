explain.depesz.com
==================

Setup
1) Mojolicious - you have to have Mojolicious installed on your server.  Mojolicious is a web framework for Perl.
http://mojolicio.us/
Installation can be accomplished with one command line:

    curl -L cpanmin.us | perl - -n Mojolicious
    
See the "Installation" section at http://mojolicio.us/ for details.

2) Perl Dependencies:
You will need the following packages installed in your version of Perl:

    Date::Simple
    Mail::Sender
    Pg::Explain
    Email::Valid

Install the above packages using "cpan" then "i Date::Simple", "i Maill::Sender" &etc.

3) PostgreSQL

A) create a new database "explain".  This will be were the explain server will store the users, histories, 
and plans in the default schema "public".

B) log into postgres as postgres. Switch to the "explain" database.  Execute the SQL scripts located in the "sql" directory 
in the following order:

    \i create.sql
    \i patch-001.sql
    \i patch-002.sql
    
The "create.sql" will create tables in the "public" schema, i.e. "plans" and "users".

B) create a user role.  I use "explaind" [explain daemon] and remember to provides it a password and then configure
the explain.json file to reflect this new role and password.

C) grant all rights to the tables in "explain" to your role "explaind":

     grant all on plans, users to explaind;
