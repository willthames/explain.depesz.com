FROM debian:stretch

WORKDIR /explain

RUN curl -L cpanmin.us | perl - -n Mojolicious
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y libmojolicious-perl \
                libemail-sender-perl \
                libdate-simple-perl \
                libemail-valid-perl \
                libxml-simple-perl  \
                libdbd-pg-perl \
                libmodule-build-perl \
                libyaml-perl \
                libjson-perl \
                libclone-perl \
                libtest-deep-perl \
                libtest-exception-perl

RUN cpan install Pg::Explain
COPY lib/ ./lib/
RUN sed -i s/Mail::Sender/Email::Sender/g lib/Explain/Plugin/MailSender.pm
COPY docker/explain.json explain.pl ./
COPY layout/ /layout/
COPY public/ ./public/
COPY templates/ ./templates

ENTRYPOINT ./explain.pl daemon
