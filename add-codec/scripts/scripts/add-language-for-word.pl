#!/usr/bin/perl

# 2020/11/16 Peng Yizhou
# Add language id for each word of a lexicon
# while phones are already labeled with language id

use strict;
use utf8;
use open qw(:std :utf8);

print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
    chomp;
    if(/^</) { # ignore special words
	print "$_\n"; next;
    }
    m/(\S+)\s+(.*)/g or next;
    my @languages = ("CHN", "CNT", "IDN", "JAP", "KZK", "KRN", "RUS", "TBT", "UYG", "VTN");
    my ($word, $phones) = ($1, $2);
    for (my $i=0; $i<scalar @languages; $i++) {
	if ($phones =~ /_$languages[$i]/ ) {
	    $word .= "_$languages[$i]"
	}
    }
    print "$word\t$phones\n";
}
print STDERR "## LOG ($0): stdin ended ...\n";
