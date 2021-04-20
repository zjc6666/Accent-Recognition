#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);

print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
    chomp;
    m/(\S+)\s+(.*)$/g or next;
    my ($w, $pron) = (lc $1, $2);
    my @A = split(/\s+/, $pron);
    my @B = ();
    for(my $i = 0; $i < scalar @A; $i ++) {
	my @part = split(//, $A[$i]);
	for(my $j = 0; $j < scalar @part; $j ++) {
	    if( $part[$j] =~ /^[0-9]+$/) {
		my $N = scalar @B;
		if ($N != 0) {
		    $B[$N-1] .= $part[$j];
		} else {
		    push @B, $part[$j];
		} 
	    } else {
		push @B, $part[$j];
	    }
	}
    }
    my $phones = join(" ", @B);
    $w =~ s/\(.*\)//;
    print "$w\t$phones\n";
}
print STDERR "## LOG ($0): stdin ended ...\n";