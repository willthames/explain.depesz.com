#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );
use File::Spec;
use FindBin;
use Data::Dumper;
use autodie;
use POSIX qw( strftime );

my $source_dir = File::Spec->catfile( $FindBin::Bin, '..', 'storage', );

my $dir;
opendir $dir, $source_dir;
my @all_files = grep { ! /^\./ && -f File::Spec->catfile( $source_dir, $_ ) } readdir $dir;
closedir $dir;

for my $file (@all_files) {
    my $full_filename = File::Spec->catfile( $source_dir, $file );
    my $mtime = (stat($full_filename))[9];
    open my $fh, '<', $full_filename;
    undef $/;
    my $content = <$fh>;
    close $fh;
    printf "INSERT INTO plans (id, plan, entered_on) VALUES ('%s', \$PLAN\$%s\$PLAN\$, '%s');\n",
        $file,
        $content,
        strftime('%Y-%m-%d %H:%M:%S', localtime $mtime);

}

exit;

