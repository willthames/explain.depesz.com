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
    return $self->render( message => 'Your plan is too long.', status  => 413 )
        if 10_000_000 < length $plan;

    # validate plan
    eval {
        my $explain = Pg::Explain->new( source => $plan );
        $explain->top_node;
    };

    # something goes wrong
    return $self->render( message => q|Failed to parse your plan.| ) if $EVAL_ERROR;

    # public
    my $is_public = $self->req->param( 'is_public' ) ? 1 : 0;

    # save to database
    my $plan_id = $self->database->save_with_random_name( $plan, $is_public );

    # redirect to /show/:plan_id
    return $self->redirect_to( 'show', 'plan_id' => $plan_id );
}

sub show {
    my $self = shift;

    # value of "/:plan_id" param
    my $plan_id = defined $self->stash->{ plan_id }
                        ? $self->stash->{ plan_id } : '';

    # missing or invalid
    return $self->redirect_to( 'index' ) unless $plan_id =~ m{\A[a-zA-Z0-9]+\z};

    # get plan source from database
    my $plan = $self->database->get_plan( $plan_id );

    # not found in database
    return $self->redirect_to( 'index', status => 404 ) unless $plan;

    # make explanation
    my $explain = eval { Pg::Explain->new( source => $plan ); };

    # plans are validated before save, so this should never happen
    if ( $EVAL_ERROR ) {
        $self->app->log->error( $EVAL_ERROR );
        return $self->redirect_to( 'index' );
    }

    # validate explain
    eval { $explain->top_node; };

    # as above, should never happen
    if ( $EVAL_ERROR ) {
        $self->app->log->error( $EVAL_ERROR );
        return $self->redirect_to( 'index' );
    }

    # put explain to stash
    $self->stash->{ explain } = $explain;

    # render will be called automatically
    return;
}

sub history {
    my $self = shift;

    # p
    my $p = $self->param( 'p' );

    # get result set from database
    my $rs = $self->database->get_public_list_paged( $p );

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
    $self->send_mail( {
        msg => sprintf(
            "\nMessage from: %s <%s>" .
            "\nPosted  from: %s with %s" .
            "\n****************************************\n\n" .
            "%s",
            $self->req->param( 'name' ) || '',
            $self->req->param( 'email' ),
            $self->tx->remote_address,
            $self->req->headers->user_agent,
            $self->req->param( 'message' )
        )
    } );

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
