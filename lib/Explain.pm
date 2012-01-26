package Explain;

use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;

    # register Explain plugins namespace
    $self->plugins->namespaces( [ "Explain::Plugin", @{ $self->plugins->namespaces } ] );

    # setup charset
    $self->plugin( charset => { charset => 'utf8' } );

    # load configuration
    my $config = $self->plugin( 'JSONConfig' );

    # setup secret passphrase
    $self->secret( $config->{ secret } || 'Xwyfe-_d:yGDr+p][Vs7Kk+e3mmP=c_|s7hvExF=b|4r4^gO|' );

    # startup database connection
    $self->plugin( 'database', $config->{ database } || {} );

    # startup mail sender
    $self->plugin( 'mail_sender', $config->{ mail_sender } || {} );

    # routes
    my $routes = $self->routes;

    # route: 'index'
    $routes->route( '/' )->to( 'controller#index' )->name( 'new-explain' );

    # route: 'show'
    $routes->route( '/s/:id' )->to( 'controller#show', id => '' )->name( 'show' );

    # route: 'history'
    $routes->route( '/history/:date' )->to( 'controller#history', date => '' )->name( 'history' );

    # route: 'contact'
    $routes->route( '/contact' )->to( 'controller#contact' )->name( 'contact' );

    # route: 'help'
    $routes->route( '/help' )->to( 'controller#help' )->name( 'help' );

    return;
}

1;
