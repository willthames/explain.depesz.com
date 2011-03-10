# IMPORTANT: if you delete this file your app will not work as
# expected.  you have been warned
use inc::Module::Install;

name 'Explain_Depesz_Com';
all_from 'lib/Explain_Depesz_Com.pm';

requires 'Catalyst::Runtime' => '5.7015';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::SmartURI';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Model::DBI';
requires 'Catalyst::View::Email';
requires 'parent';
requires 'Pg::Explain';
requires 'Email::Valid';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
