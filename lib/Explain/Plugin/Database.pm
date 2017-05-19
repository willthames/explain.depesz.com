package Explain::Plugin::Database;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util 'trim';

use Carp;
use DBI;
use Date::Simple;
use English qw( -no_match_vars );

has dbh             => undef;
has connection_args => sub { [] };
has log             => undef;

sub register {
    my ( $self, $app, $config ) = @_;

    # data source name
    my $dsn = $config->{ dsn };

    # if DSN not set directly
    unless ( $dsn ) {

        # driver
        my $driver = $config->{ driver } || 'Pg';

        # database name
        my $database = $config->{ database } || lc( $ENV{ MOJO_APP } );

        # assemble
        my $dsn = sprintf 'dbi:%s:database=%s', $driver, $database;

        $dsn .= ';host=' . $config->{ host } if $config->{ host };
        $dsn .= ';port=' . $config->{ port } if $config->{ port };
    }

    # database (DBI) connection arguments
    $self->connection_args(
        [
            $config->{ dsn },
            $config->{ username },
            $config->{ password },
            $config->{ options } || {}
        ]
    );

    # log debug message
    $app->log->debug( 'Database connection args: ' . $app->dumper( $self->connection_args ) );
    $self->log( $app->log );

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

sub user_login {
    my $self = shift;
    my ( $username, $password ) = @_;

    my @row = $self->dbh->selectrow_array(
        'SELECT password, is_admin FROM users where username = ?',
        undef,
        $username,
    );
    return if 0 == scalar @row;
    my $crypted = crypt( $password, $row[ 0 ] );

    return if $crypted ne $row[ 0 ];
    return { 'admin' => $row[1] };
}

sub user_change_password {
    my $self = shift;
    my ( $username, $old, $new ) = @_;

    my @row = $self->dbh->selectrow_array(
        'SELECT password FROM users where username = ?',
        undef,
        $username,
    );
    return if 0 == scalar @row;
    my $crypted_old = crypt( $old, $row[ 0 ] );

    my $crypted_new = crypt( $new, $self->get_pw_salt() );

    @row = $self->dbh->selectrow_array(
        'UPDATE users SET password = ? WHERE ( username, password ) = ( ?, ? ) returning username',
        undef,
        $crypted_new, $username, $crypted_old,
    );
    return 1 if 1 == scalar @row;
    return;
}

sub get_user_history {
    my $self = shift;
    my ( $user, $direction, $marker ) = @_;

    my $limit = 100;

    $direction = 'DESC' if ( $direction // '' ) ne 'ASC';
    my $query = '';
    my @args  = ();

    if ( defined $marker ) {
        my $comparison = $direction eq 'DESC' ? '<' : '>';
        $query = "
            SELECT p.id, p.entered_on::date, p.is_public, p.is_anonymized, p.title
            FROM plans p
            WHERE p.added_by = ? and not p.is_deleted
            AND ( p.entered_on, p.id ) $comparison (
                    select x.entered_on, x.id
                    from plans x
                    where x.id = ?
                )
            ORDER BY p.entered_on $direction, p.id $direction LIMIT $limit
            ";
        @args = ( $user, $marker );

    }
    else {
        $query = "
            SELECT p.id, p.entered_on::date, p.is_public, p.is_anonymized, p.title
            FROM plans p
            WHERE p.added_by = ? and not p.is_deleted
            ORDER BY p.entered_on DESC, p.id DESC LIMIT $limit
            ";
        @args = ( $user );
    }
    my $plans = $self->dbh->selectall_arrayref( $query, { Slice => {} }, @args );

    # newest plans always first
    $plans = [ reverse @{ $plans } ] if $direction eq 'ASC';

    return {
        'list'    => [],
        'earlier' => 0,
        'later'   => 0,
    } if 0 == scalar @{ $plans };

    my @later = $self->dbh->selectrow_array(
        'SELECT p.id FROM plans p where p.added_by = ? and not is_deleted and ( p.entered_on, p.id ) > ( select x.entered_on, x.id from plans x where x.id = ? ) limit 1',
        undef,
        $user, $plans->[ 0 ]->{ 'id' },
    );
    my @earlier = $self->dbh->selectrow_array(
        'SELECT p.id FROM plans p where p.added_by = ? and not is_deleted and ( p.entered_on, p.id ) < ( select x.entered_on, x.id from plans x where x.id = ? ) limit 1',
        undef,
        $user, $plans->[ -1 ]->{ 'id' },
    );
    return {
        'list'    => $plans,
        'later'   => scalar @later,
        'earlier' => scalar @earlier,
    };
}

sub get_pw_salt {
    my $self       = shift;
    my @salt_chars = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9, '.', '/' );
    my $salt       = sprintf '$6$%s$', join( '', map { $salt_chars[ rand @salt_chars ] } 1 .. 16 );
    return $salt;
}

sub user_register {
    my $self = shift;
    my ( $username, $password ) = @_;

    my $crypted = crypt( $password, $self->get_pw_salt() );

    eval { $self->dbh->do( 'INSERT INTO users (username, password, registered) values (?, ?, now())', undef, $username, $crypted, ); };
    return 1 unless $EVAL_ERROR;
    $self->log->error( "user_register( $username ) => " . $EVAL_ERROR );
    return;
}

sub update_plan {
    my $self = shift;
    my ( $id, $changes ) = @_;
    my @columns = keys %{ $changes };
    my @values  = values %{ $changes };

    eval {
        $self->dbh->do(
            'UPDATE plans SET ' . join( ', ', map { "$_ = ?" } @columns ) . ' WHERE id = ?',
            undef,
            @values, $id
        );
    };
    return 1 unless $EVAL_ERROR;
    $self->log->error( "update_plan( $id ) => " . $EVAL_ERROR );
    return;
}

sub save_with_random_name {
    my $self = shift;
    my ( $title, $content, $is_public, $is_anon, $username, $optimization_for ) = @_;

    my @row = $self->dbh->selectrow_array(
        'SELECT id, delete_key FROM register_plan(?, ?, ?, ?, ?, ?)',
        undef,
        $title, $content, $is_public, $is_anon, $username, $optimization_for,
    );

    # return id and delete_key
    return @row;
}

sub get_plan_data {
    my $self = shift;
    my ( $plan_id ) = @_;

    my $rows = $self->dbh->selectall_arrayref(
        'SELECT * FROM plans WHERE id = ? AND NOT is_deleted',
        { Slice => {} },
        $plan_id,
    );
    return unless defined $rows;
    return if 0 == scalar @{ $rows };
    return $rows->[ 0 ];
}

sub get_plan {
    my $self = shift;
    my ( $plan_id ) = @_;

    my @row = $self->dbh->selectrow_array(
        'SELECT plan, title, optimization_for FROM plans WHERE id = ? AND NOT is_deleted',
        undef,
        $plan_id,
    );

    # return plan
    return @row;
}

sub get_optimization_path {
    my $self = shift;
    my ($plan_id) = @_;

    my $rows = $self->dbh->selectall_arrayref(
        '
            WITH RECURSIVE path AS (
                SELECT id, title, optimization_for, 0 as level FROM plans WHERE id = ? and not is_deleted
                union all
                SELECT p.id, p.title, p.optimization_for, x.level + 1
                    FROM path x
                    join plans p on p.id = x.optimization_for
                    WHERE NOT p.is_deleted
                        AND x.optimization_for IS NOT NULL
            )
            SELECT
                id, title
            FROM
                path
            ORDER BY level desc;
        ',
        { Slice => {} },
        $plan_id,
    );
    return if 0 == scalar @{ $rows };
    return if 1 == scalar @{ $rows };
    return $rows;
}

sub get_optimizations_for {
    my $self = shift;
    my ($plan_id) = @_;
    my $rows = $self->dbh->selectall_arrayref(
        'select id, title from plans where optimization_for = ? and not is_deleted',
        { Slice => {} },
        $plan_id
    );
    return if 0 == scalar @{ $rows };
    return $rows;
}

sub plan_exists {
    my $self = shift;
    my ( $plan_id ) = @_;

    my @row = $self->dbh->selectrow_array(
        'SELECT 1 FROM plans WHERE id = ? AND NOT is_deleted',
        undef,
        $plan_id,
    );
    return if 0 == scalar @row;
    return 1;
}

sub delete_plan {
    my $self = shift;
    my ( $plan_id, $delete_key ) = @_;
    my @row = $self->dbh->selectrow_array(
        'UPDATE plans SET plan = ?, title = ?, is_deleted = true, delete_key = NULL WHERE id = ? and delete_key = ? RETURNING 1',
        undef,
        '',
        'This plan has been deleted.',
        $plan_id,
        $delete_key
    );
    return 1 if $row[ 0 ];
    return;
}

sub get_public_list {
    my $self = shift;

    return $self->dbh->selectall_arrayref(
        'SELECT id, to_char( entered_on, ? ) as date FROM plans WHERE is_public ORDER BY entered_on DESC',
        { Slice => {} },
        'YYYY-MM-DD'
    );
}

sub get_public_list_paged {
    my $self = shift;

    # param "date"
    my $date = defined( $_[ 0 ] ) ? $_[ 0 ] : '';

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
            AND NOT is_deleted
       ORDER BY entered_on
           DESC',
        { Slice => {} },
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
