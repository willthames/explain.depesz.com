package Explain_Depesz_Com::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use English qw( -no_match_vars );
use Email::Valid;
use Pg::Explain;
use Data::Dumper;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Explain_Depesz_Com::Controller::Root - Root Controller for Explain_Depesz_Com

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    return;
}

sub help : Local {
    my ( $self, $c ) = @_;
    return;
}

sub contact : Local {
    my ( $self, $c ) = @_;

    return unless $c->req->param('message');
    return unless $c->req->param('message') =~ m{\S};

    unless (Email::Valid->address( $c->req->param('email') || '' )) {
        $c->stash->{'errors'}->{'bad_email'} = 1;
        return;
    }

    my $message_body = 'Message from: ' . $c->req->param('name') . ' <' . $c->req->param('email') . '>';
    $message_body .= "\nPosted from: " . $c->req->address . " with " . $c->req->header('User-Agent');
    $message_body .= "\n\n***************************\n\n";
    $message_body .= $c->req->param('message');

    $c->stash->{'email'} = {
        'header' => [
            'To'      => 'depesz@depesz.com',
            'From'    => 'depesz@depesz.com',
            'Subject' => 'Contact form on explain.depesz.com',
        ],
        'body'    => $message_body,
    };

    $c->forward($c->view('Email'));
    
    return;
}

sub history : Local {
    my ( $self, $c ) = @_;

    my @plans = $c->model('DBI')->get_public_list();

    $c->stash->{'plans'} = \@plans;

    return;
}

sub show : Path('s') : Args(1) {
    my ( $self, $c ) = @_;

    my $explain_code = $c->req->args->[0];

    return $c->detach('default') unless $explain_code =~ m{\A[a-zA-Z0-9]+\z};

    my $explain = eval {
        Pg::Explain->new(
            'source' => $c->model('DBI')->get_plan( $explain_code ),
        );
    };
    if ($EVAL_ERROR) {
        print STDERR $EVAL_ERROR;
        $c->detach('default');
    }

    eval {
        my $tmp = $explain->top_node;
    };
    return $c->res->redirect('/') if $EVAL_ERROR;

    $c->stash->{'explain_code'} = $explain_code;
    $c->stash->{'explain'} = $explain;

    return;
}

sub new_explain : Path('new') : Args(0) {
    my ( $self, $c ) = @_;

    my $explain = $c->req->param('explain');
    my $public = $c->req->param('public') ? 1 : 0;

    eval {
        my $e = Pg::Explain->new( 'source' => $explain, );
        my $t = $e->top_node();
    };
    return $c->res->redirect('/') if $EVAL_ERROR;

    if (length($explain) > 10_000_000) {
        $c->response->body( 'Too long explain' );
        $c->response->status(413);
        return;
    }

    my $code = $c->model('DBI')->save_with_random_name( $explain, $public, );

    $c->res->redirect( $c->uri_for( 's', $code ));

    return;
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
    return;
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') { }

=head1 AUTHOR

hubert depesz lubaczewski,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
