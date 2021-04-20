#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);

print STDERR "## LOG ($0): stdin expected ...\n";
my %vocab = ();
while(<STDIN>) {
    chomp;
    m/(\S+)\s+(\S+)$/g or next;
    my $final = $2;
    my $untoned = $final;
    $untoned =~ s/[0-9]//g;
    my $ref = "";
    if(exists $vocab{$untoned}) {
      $ref = $vocab{$untoned};
    }else {
      my %v = ();
      $vocab{$untoned} = \%v;
      $ref = $vocab{$untoned};
    }
    $$ref{$final} ++;
}
print STDERR "## LOG ($0): stdin ended ...\n";

foreach my $key (keys%vocab) {
  my $ref = $vocab{$key};
  foreach my $final (keys%$ref) {
    print "$final ";
  }
  print "\n";
}
