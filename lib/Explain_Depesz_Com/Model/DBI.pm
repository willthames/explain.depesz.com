package Explain_Depesz_Com::Model::DBI;

use strict;
use base 'Catalyst::Model::DBI';

sub save_with_random_name {
    my $self      = shift;
    my $content   = shift;
    my $is_public = shift;

    my $sth = $self->dbh->prepare( 'SELECT register_plan(?, ?)' );
    $sth->execute( $content, $is_public );
    my @row = $sth->fetchrow_array;
    $sth->finish;

    return $row[ 0 ];
}

sub get_plan {
    my $self = shift;
    my $code = shift;

    my $sth = $self->dbh->prepare( 'SELECT plan FROM plans WHERE id = ?' );
    $sth->execute( $code );
    my @row = $sth->fetchrow_array;
    $sth->finish;

    return $row[ 0 ];
}

sub get_public_list {
    my $self = shift;

    my @reply;
    my $sth = $self->dbh->prepare( 'SELECT id, to_char(entered_on, ?) as day FROM plans WHERE is_public ORDER BY entered_on DESC' );
    $sth->execute( 'YYYY-MM-DD' );
    while ( my $row = $sth->fetchrow_hashref ) {
        push @reply, $row;
    }
    $sth->finish;

    return @reply;
}

1;
