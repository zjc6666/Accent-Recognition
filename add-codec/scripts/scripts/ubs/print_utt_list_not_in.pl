#!/usr/bin/perl -w 
use strict;
use utf8;
use open qw (:std :utf8);

my $numArgs = scalar @ARGV;
my $usage = <<"EOF";

  cat uttlist.txt |  $0  to_be_excluded_uttlist.txt

EOF
if ($numArgs != 1) {
  die $usage;
}

my ($uttlist) = @ARGV;

# begin sub
sub LoadVocab {
  my ($vocab, $infile) = @_;
  open (F, "$infile") or die "#ERROR ($0): cannot open file '$infile'\n";
  while(<F>) {
    chomp;
    m/^(\S+)\s*(.*)/g or next;
    $$vocab{$1} ++;
  }
  close F;
}
# end sub
my %vocab = ();
LoadVocab(\%vocab, $uttlist);

print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
  chomp;
  m/^(\S+)\s*(.*)/g or next;
  my $uttid = $1;
  if(not exists $vocab{$uttid}) {
    print "$_\n";
  }
}
print STDERR "## LOG ($0): stdin ended ...\n";
