package Explain::Controller;

use Mojo::Base 'Mojolicious::Controller';

use English -no_match_vars;

use Pg::Explain;
use Email::Valid;

sub index {
    my $self = shift;

    # plan
    my $plan = $self->req->param( 'plan' );

    # nothing to do...
    return $self->render unless $plan;

    # request entity too large
    return $self->render( message => 'Your plan is too long.', status => 413 )
        if 10_000_000 < length $plan;

    # public
    my $is_public = $self->req->param( 'is_public' ) ? 1 : 0;

    # anonymization
    my $is_anon = $self->req->param( 'is_anon' ) ? 1 : 0;

    # plan title
    my $title = $self->req->param( 'title' );
    $title = '' unless defined $title;
    $title = '' if 'Optional title' eq $title;

    # try
    eval {

        # make "explain"
        my $explain = Pg::Explain->new( source => $plan );

        # something goes wrong...
        die q|Can't create explain! Explain "top_node" is undef!|
            unless defined $explain->top_node;

        # Anonymize plan, when requested.
        if ( $is_anon ) {
            $explain->anonymize();
            $plan = $explain->as_text();
        }

    };

    # catch
    if ( $EVAL_ERROR ) {

        # log message
        $self->app->log->info( $EVAL_ERROR );

        # try
        eval {

            # send mail
            $self->send_mail(
                {
                    subject => q|Can't create explain from...|,
                    msg     => $plan
                }
            );
        };

        # leave...
        return $self->render( message => q|Failed to parse your plan| );
    }

    # save to database
    my $id = $self->database->save_with_random_name( $title, $plan, $is_public, $is_anon, );

    # redirect to /show/:id
    return $self->redirect_to( 'show', id => $id );
}

sub show {
    my $self = shift;

    # value of "/:id" param
    my $id = defined $self->stash->{ id } ? $self->stash->{ id } : '';

    # missing or invalid
    return $self->redirect_to( 'new-explain' ) unless $id =~ m{\A[a-zA-Z0-9]+\z};

    # get plan source from database
    my ( $plan, $title ) = $self->database->get_plan( $id );

    # not found in database
    return $self->redirect_to( 'new-explain', status => 404 ) unless $plan;

    # make explanation
    my $explain = eval { Pg::Explain->new( source => $plan ); };

    # plans are validated before save, so this should never happen
    if ( $EVAL_ERROR ) {
        $self->app->log->error( $EVAL_ERROR );
        return $self->redirect_to( 'new-explain' );
    }

    # validate explain
    eval { $explain->top_node; };

    # as above, should never happen
    if ( $EVAL_ERROR ) {
        $self->app->log->error( $EVAL_ERROR );
        return $self->redirect_to( 'new-explain' );
    }

    # Get stats from plan
    my $stats = { 'tables' => {} };
    my @elements = ( $explain->top_node );
    while ( my $e = shift @elements ) {
        push @elements, values %{ $e->ctes } if $e->ctes;
        push @elements, @{ $e->sub_nodes }   if $e->sub_nodes;
        push @elements, @{ $e->initplans }   if $e->initplans;
        push @elements, @{ $e->subplans }    if $e->subplans;

        $stats->{'nodes'}->{ $e->type }->{'count'}++;
        $stats->{'nodes'}->{ $e->type }->{'time'}+=$e->total_exclusive_time if $e->total_exclusive_time;

        next unless $e->scan_on;
        next unless $e->scan_on->{ 'table_name' };
        $stats->{ 'tables' }->{ $e->scan_on->{ 'table_name' } } ||= {};
        my $S = $stats->{ 'tables' }->{ $e->scan_on->{ 'table_name' } };
        $S->{ $e->{ 'type' } }->{ 'count' }++;
        $S->{ ':total' }->{ 'count' }++;
        if ( defined( my $t = $e->total_exclusive_time ) ) {
            $S->{ $e->type }->{ 'time' } += $t;
            $S->{ ':total' }->{ 'time' } += $t;
        }
    }

    # put explain and title to stash
    $self->stash->{ explain } = $explain;
    $self->stash->{ title }   = $title;
    $self->stash->{ stats }   = $stats;

    # render will be called automatically
    return;
}

sub history {
    my $self = shift;

    # date
    my $date = $self->param( 'date' );

    # get result set from database
    my $rs = $self->database->get_public_list_paged( $date );

    # put result set to stash
    $self->stash( rs => $rs );

    return;
}

sub contact {
    my $self = shift;

    # nothing to do...
    return unless $self->req->param( 'message' );

    # invalid email address
    return $self->render( error => 'Invalid email address' )
        unless Email::Valid->address( $self->req->param( 'email' ) || '' );

    # send
    $self->send_mail(
        {
            msg => sprintf(
                "\nMessage from: %s <%s>" . "\nPosted  from: %s with %s" . "\n****************************************\n\n" . "%s",
                $self->req->param( 'name' ) || '',
                $self->req->param( 'email' ),
                $self->tx->remote_address,
                $self->req->headers->user_agent,
                $self->req->param( 'message' )
            )
        }
    );

    # mail sent message
    $self->flash( message => 'Mail sent' );

    # get after post
    $self->redirect_to( 'contact' );
}

sub help {

    # direct to template
    return ( shift )->render;
}

1;
