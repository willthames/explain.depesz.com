package Explain::Plugin::Database;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util 'trim';

use Carp;
use DBI;
use Date::Simple;

has dbh             => undef;
has connection_args => sub { [] };

sub register {
    my ( $self, $app, $config ) = @_;

    # data source name
    my $dsn = $config->{ dsn };

    # if DSN not set directly
    unless ( $dsn ) {

        # driver
        my $driver = $config->{ driver }   || 'Pg';

        # database name
        my $database = $config->{ database } || lc( $ENV{ MOJO_APP } );

        # assemble
        my $dsn = sprintf 'dbi:%s:database=%s', $driver, $database;

        $dsn .= ';host=' . $config->{ host } if $config->{ host };
        $dsn .= ';port=' . $config->{ port } if $config->{ port };
    }

    # database (DBI) connection arguments
    $self->connection_args( [
        $config->{ dsn },
        $config->{ username },
        $config->{ password },
        $config->{ options } || {}
    ] );

    # log debug message
    $app->log->debug( 'Database connection args: ' . $app->dumper( $self->connection_args ) );

    # register helper
    $app->helper(
        database => sub {

            # not conected yet
            unless ( $self->dbh ) {

                # connect
                $self->dbh( DBI->connect( @{ $self->connection_args } ) );

                # raise error (for case, when "RaiseError" option is not set)
                confess qq|Can't connect database| unless $self->dbh;
            }

            return $self;
        }
    );

    return;
}

sub save_with_random_name {
    my ( $self, $content, $is_public ) = @_;

    # create statement handler
    my $sth = $self->dbh->prepare( 'SELECT register_plan(?, ?)' );

    # execute
    $sth->execute( $content, $is_public );

    # register_plan returns plan id
    my @row = $sth->fetchrow_array;

    # finish
    $sth->finish;

    # return plan id
    return $row[ 0 ];
}

# @depesz
#  - why you don't use selectrow_array (or similar)?
sub get_plan {
    my ( $self, $plan_id ) = @_;

    # create statement handler
    my $sth = $self->dbh->prepare( 'SELECT plan FROM plans WHERE id = ?' );

    # execute
    $sth->execute( $plan_id );

    # fetch row
    my @row = $sth->fetchrow_array;

    # finish
    $sth->finish;

    # return plan
    return $row[ 0 ];
}

sub get_public_list {
    my $self = shift;

    return $self->dbh->selectall_arrayref(
        'SELECT id, to_char( entered_on, ? ) as date FROM plans WHERE is_public ORDER BY entered_on DESC',
        { Slice => { } },
        'YYYY-MM-DD'
    );
} 

sub get_public_list_paged {
    my $self = shift;

    # param "date"
    my $date = defined( $_[0] ) ? $_[0] : '';

    # trim
    trim $date;

    # today
    my $today = Date::Simple->new;

    # scalar $date to Date::Simple
    my $to = eval { Date::Simple->new( $date ) };

    # error
    unless ( $to ) {

        # invalid date, like: 2010-02-31
        return { error => qq|Invalid date "$date" given.| }
            if $date =~ /\A\d\d\d\d\-\d\d\-\d\d\z/;

        # invalid format
        return { error => qq|Invalid value "$date" given.| }
            if length $date;

        # fallback
        $to = $today;
    }

    # time travel exception
    return { error => qq|Date "$date" is in future!| } if $to > $today;

    # since SCALAR value
    my $since = ( $to - 7 )->as_str( '%Y-%m-%d' );

    # select
    my $rows = $self->dbh->selectall_arrayref(
        'SELECT id, to_char( entered_on, ? ) as date
           FROM plans
          WHERE is_public
            AND entered_on > ?::date
            AND entered_on < ?::date
       ORDER BY entered_on
           DESC',
        { Slice => { } },
        'YYYY-MM-DD',
        $since,
        ( $to + 1 )->as_str( '%Y-%m-%d' )
    );

    # next week
    my $next = $to + 7;
       $next = ( $next > $today ) ? undef : $next->as_str( '%Y-%m-%d' );

    return {
        since     => $since,
        to        => $to->as_str( '%Y-%m-%d' ),
        rows      => $rows || [],
        next_date => $next,
        prev_date => ( $to - 8 )->as_str( '%Y-%m-%d' )
    };
}

sub DESTROY {
    my $self = shift;

    # nothing to do...
    return unless $self->dbh;

    # rollback uncommited transactions
    $self->dbh->rollback unless $self->connection_args->[ 3 ]->{ auto_commit };

    # disconnect
    $self->dbh->disconnect;

    $self->dbh( undef );

    return;
}

1;
