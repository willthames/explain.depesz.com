package Explain;

use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;

    $self->sessions->cookie_name( 'explain' );
    $self->sessions->default_expiration( 60 * 60 * 24 * 365 );

    # register Explain plugins namespace
    $self->plugins->namespaces( [ "Explain::Plugin", @{ $self->plugins->namespaces } ] );

    # load configuration
    my $config = $self->plugin( 'JSONConfig' );

    # setup secret passphrase - later versions of
    # mojolicious require secrets to be multiple in an
    # array format
    my $use_secret = $config->{ secret } || 'Xwyfe-_d:yGDr+p][Vs7Kk+e3mmP=c_|s7hvExF=b|4r4^gO|';
    if ( $self->can( 'secrets' ) ) {
        # We're on Mojolicious 4.63 or newer
        $self->secrets( [ $use_secret ] );
    } else {
        # We're on old Mojolicious
        $self->secret( $use_secret );
    }

    # startup database connection
    $self->plugin( 'database', $config->{ database } || {} );

    # startup mail sender
    $self->plugin( 'mail_sender', $config->{ mail_sender } || {} );

    # load number_format plugin
    $self->plugin( 'number_format' );

    # routes
    my $routes = $self->routes;

    # route: 'index'
    $routes->route( '/' )->to( 'controller#index' )->name( 'new-explain' );

    # route: 'new-optimization'
    $routes->route( '/new_optimization' )->to( 'controller#new_optimization' )->name( 'new-optimization' );

    # route: 'user-history'
    $routes->route( '/user-history/:direction/:key' )->to( 'controller#user_history', direction => undef, key => undef )->name( 'user-history' );

    # route: 'plan-change'
    $routes->route( '/plan-change/:id' )->to( 'controller#plan_change' )->name( 'plan-change' );

    # route: 'login'
    $routes->route( '/login' )->to( 'controller#login' )->name( 'login' );

    # route: 'logout'
    $routes->route( '/logout' )->to( 'controller#logout' )->name( 'logout' );

    # route: 'user'
    $routes->route( '/user' )->to( 'controller#user' )->name( 'user' );

    # route: 'show'
    $routes->route( '/s/:id' )->to( 'controller#show', id => '' )->name( 'show' );

    # route: 'delete'
    $routes->route( '/d/:id/:key' )->to( 'controller#delete', id => '', key => '' )->name( 'delete' );

    # route: 'history'
    $routes->route( '/history/:date' )->to( 'controller#history', date => '' )->name( 'history' );

    # route: 'contact'
    $routes->route( '/contact' )->to( 'controller#contact' )->name( 'contact' );

    # route: 'help'
    $routes->route( '/help' )->to( 'controller#help' )->name( 'help' );

    # route: 'info'
    $routes->route( '/info' )->to( 'controller#info' )->name( 'info' );

    return;
}

1;
