package Explain::Plugin::NumberFormat;

use Mojo::Base 'Mojolicious::Plugin';

use Mail::Sender;

sub register {
    my ( $self, $app ) = @_;

    # register helper
    $app->helper(
        commify_numbers => sub {
            my $self = shift;

            # Code taken from perlfaq5
            local $_ = shift;
            return $_ unless defined $_;
            1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
            return $_;
        }
    );
}

1;
