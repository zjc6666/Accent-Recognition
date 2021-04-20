#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);

my $count = 0;
print STDERR "\n## LOG ($0): wav.scp input expected ...\n";
while (<STDIN>) {
    chomp;
    $count ++;
    if ($count < 2) {
      print STDERR "\n## LOG ($0): see wav.scp input ...\n";
    }
    if(m/(\-r 8000 \-c 1)/) {
      s/$1/\-r 16000 \-c 1/;
      print "$_\n";
    } else {
      if (/\|\s*$/) {
	m/(\S+)\s+(.*)$/ or next;
	my ($wavid, $wavpipe) = ($1, $2);
	$wavpipe = "$wavpipe sox -r 8000 - -r 16000 -c 1 -b 16 -t wav - |";
	print "$wavid $wavpipe\n";
      } elsif (/\.wav\s*$/) {
	my @A = split(/\s+/);
	if (scalar @A != 2) {
	  die "## ERROR ($0): unexpected wave entry: '$_'\n";
	}
	# /usr/bin/sox -r 8000 /data/users/hhx502/w2016/sg-en-i2r/CategoryI/Wave/Speaker201/Speaker201-1.pcm -r 16000 -c 1 -b 16 -t wav - |
	$A[1] = "sox $A[1] -r 16000 -c 1 -b 16 -t wav - |";
	print "$A[0] $A[1]\n";
      } else {
	die "## ERROR ($0): illegal wave entry : '$_'\n";
      }
    }
}
print STDERR "\n## LOG ($0): wav.scp input is done ...\n";
