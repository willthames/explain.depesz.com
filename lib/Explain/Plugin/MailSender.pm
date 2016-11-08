package Explain::Plugin::MailSender;

use Mojo::Base 'Mojolicious::Plugin';

# Mail Sender is broken on new perls, and I can't migrate to another mail sending module now (vacation time)
BEGIN {
    eval {
        require Mail::Sender;
    };
}

__PACKAGE__->attr( config => sub { {} } );

sub register {
    my ( $self, $app, $config ) = @_;

    # save settings
    $self->config( $config );

    # register helper
    $app->helper(
        send_mail => sub {
            my ( $controller, $mail ) = @_;

            # update mail params with config values
            for ( qw( smtp port subject from to cc bcc replyto confirm ) ) {

                # skip if not set in config
                next unless $self->config->{ $_ };

                # update mail unless value not set directly
                $mail->{ $_ } ||= $self->config->{ $_ };
            }

            # set default smtp
            $mail->{ smtp } ||= '127.0.0.1';

            # set mail charset and content type
            $mail->{ charset } = 'utf-8';
            $mail->{ ctype }   = 'text/plain';

            # log debug message
            $controller->app->log->debug( sprintf "Sending mail:\n%s", $controller->dumper( $mail ) );

            # create Mail::Sender instance
            my $sender = Mail::Sender->new(
                {
                    smtp => delete $mail->{ smtp },
                    from => delete $mail->{ from }
                }
            );

            # unable to create instance
            unless ( ref $sender ) {

                # error message
                my $message = qq|Can't create Mail::Sender instance, reason: [$sender] "$Mail::Sender::Error"|;

                # log error message
                $controller->app->log->fatal( $message );

                # die
                die $message;
            }

            # send mail
            my $result = $sender->MailMsg( $mail );

            # unable to sent mail
            unless ( ref $result ) {

                # error message
                my $message = qq|Mail send failed, reason: [$result] "$Mail::Sender::Error"|;

                # log error message
                $controller->app->log->fatal( $message );

                # die
                die $message;
            }

            # success
            return 1;
        }
    );
}

1;
