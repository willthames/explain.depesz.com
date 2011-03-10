package Explain::Plugin::Database;

use Mojo::Base 'Mojolicious::Plugin';

use Carp;
use DBI;

__PACKAGE__->attr( dbh => undef );

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
    $app->log->debug( 'Connecting database using: ' . $app->dumper( $self->connection_args ) );

    # connect
    $self->dbh( DBI->connect( @{ $self->connection_args } ) );

    # raise error (for case, when "RaiseError" option is not set)
    confess qq|Can't connect database| unless $self->dbh;

    # register helper
    $app->helper(
        database => sub { $self }
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

    my $p     = ( shift || '' ) =~ /\A(\d+)\z/ ? $1 : 1;
    my $limit = ( shift || '' ) =~ /\A(\d+)\z/ ? $1 : 30;

    # result, response...
    my $rs = {
        page          => $p,
        rows_per_page => $limit,
        has_previous  => ( $p > 1 ? 1 : 0 ),
        has_next      => 0,
        rows          => []
    };

    # OFFSET
    my $offset = ( $p - 1 ) * $limit;

    # LIMIT = $limit + 1, to see do we have "next"
    $limit++;

    # select
    my $rows = $self->dbh->selectall_arrayref(
        'SELECT id, to_char( entered_on, ? ) as date FROM plans WHERE is_public ORDER BY entered_on DESC LIMIT ? OFFSET ?',
        { Slice => { } },
        'YYYY-MM-DD', $limit, $offset
    );

    # got results
    if ( my $count = scalar @{ $rows || [] } ) {

        # there is more (at least 1 more)
        if ( $count == $limit ) {

            # set "has_next"
            $rs->{ has_next } = 1;

            # remove "test" row
            pop @{ $rows };
        }

        # set "rows"
        $rs->{ rows } = $rows;
    }

    return $rs;
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
