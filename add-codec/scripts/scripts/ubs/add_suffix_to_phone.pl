#!/usr/bin/perl -w 
use strict;
use utf8;
use open qw(:std :utf8);

my $numArgs = scalar @ARGV;
if ($numArgs != 1) {
  die "\ncat dict.txt | $0 _man\n\n";
}
my $suffix = shift @ARGV;
print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
  chomp;
  m/(\S+)\s+(.*)/g or next;
  my ($word, $pron) = ($1, $2);
  my @A = split(/\s+/, $pron);
  for(my $i = 0; $i < scalar @A; $i ++) {
    $A[$i] = $A[$i] . $suffix;
  }
  $pron = join(" ", @A);
  print "$word\t$pron\n";
}
print STDERR "## LOG ($0): stdin ended ...\n";
