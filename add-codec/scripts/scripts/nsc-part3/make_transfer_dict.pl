#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);
# begin sub
sub DoTransfer {
    my ($s) = @_;
    $$s =~ s/\#//g;
    $$s =~ s/\!//g;  $$s =~ s/[\[\]]//g;
    $$s =~ s/\(pp.*$//g;
    $$s =~ s/[\(\)]//g;  $$s =~ s/\~//g;
}
# end sub
print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
    chomp;
    m/^(\S+)\s+(.*)/g or next;
    my $original = $1;
    my $transferred = $original;
    DoTransfer(\$transferred);
    print "$original\t$transferred\n";
}
print STDERR "## LOG ($0): stdin ended ...\n";
