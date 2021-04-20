#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);

my $num_args = scalar @ARGV;

if($num_args != 1) {
  die "\nUsage:cat segments | $0 wavid-list.txt > utt-list.txt\n\n";
}

my ($wavid_file) = @ARGV;

my %vocab = ();

# begin sub
sub LoadVocab {
  my ($infile, $vocab) = @_;
  open (F, "$infile") or die;
  while(<F>) {
    chomp;
    m/^(\S+)$/g or next;
    $$vocab{$1} ++;
  }
  close F;
}
# end sub
LoadVocab($wavid_file, \%vocab);

print STDERR "# LOG ($0): stdin expected ...\n";
while(<STDIN>) {
  chomp;
  my @A = split(/\s+/);
  my ($uttid, $wavid) = ($A[0], $A[1]);
  if(exists $vocab{$A[1]}) {
    print "$A[0]\n";
  }
}
print STDERR "## LOG ($0): stdin ended ...\n";
