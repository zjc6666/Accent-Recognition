#!/usr/bin/perl
use strict;
use utf8;
use open qw(:std :utf8);

my $numArgs = scalar @ARGV;

if ($numArgs != 1) {
    die "\nExample: cat lexicon.txt | $0 <langid>\n\n";
}

my ($langid) = @ARGV;

print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
    chomp;
    if(/^</) { # ignore special words
	print "$_\n"; next;
    }
    m/(\S+)\s+(.*)/g or next;
    my ($word, $phones) = ($1, $2);
    my @A = split(/\s+/, $phones);
    for(my $i = 0; $i < scalar @A; $i ++) {
	$A[$i] .= "_$langid";
    }
    $phones = join(" ", @A);
    print "$word\t$phones\n";
}
print STDERR "## LOG ($0): stdin ended ...\n";
