#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);
use Getopt::Long;

my $wavid_prefix = "";
my $raw_wavid;
GetOptions('wavid-prefix|wavid_prefix=s' => \$wavid_prefix,
    'raw-wavid|raw_wavid' => \$raw_wavid) or die;

print STDERR "## LOG ($0): wavlist.txt input expected ...\n";
while(<STDIN>) {
  chomp;
  my @A = split(/[\/]/);
  my $N = scalar @A;
  my ($dir, $fname) = ($A[$N-2], $A[$N-1]);
  $fname =~ s/\.wav//g;
  my $wavid;
  if ($raw_wavid) {
      $wavid = $fname;
  } else {
      $wavid = lc $dir . '_' . $fname;
  }
  if($wavid_prefix ne "") {
    $wavid = $wavid_prefix . '-' . $wavid;
  }
  # die "wavid = $wavid\n";
  print "$wavid $_\n";
}
print STDERR "## LOG ($0): wavlinst.txt input done ...\n";
