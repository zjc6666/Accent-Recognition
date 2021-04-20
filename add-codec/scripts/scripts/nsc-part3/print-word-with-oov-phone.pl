#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);

my $numArgs = scalar @ARGV;
if($numArgs != 1) {
  die "\nExample: cat lexicon.txt | $0 phone-list.txt\n\n";
}

my ($phone_list_infile) = @ARGV;

# begin sub
sub LoadPhoneList {
  my ($infile, $vocab) = @_;
  open(F, "$infile") or die;
  while(<F>) {
    chomp;
    m/^\s*(\S+)\s*/g;
    $$vocab{$1} ++;
  }
  close F;
}
# end sub
my %vocab = ();
LoadPhoneList($phone_list_infile, \%vocab);
print STDERR "## LOG ($0): lexicon entry line expected ...\n";
my %oov_phone_list = ();
my %oov_word = ();
while(<STDIN>) {
  chomp;
  m/(\S+)\s+(.*)/g or next;
  my ($word, $phones) = ($1, $2);
  my @A = split(/\s+/, $phones);
  my $has_oov_phone = 0;
  for(my $i = 0; $i < scalar @A; $i ++) {
    my $phone = $A[$i];
    if(not exists $vocab{$phone}) {
      $has_oov_phone ++;
      $oov_phone_list{$phone} ++;
    }
  }
  if($has_oov_phone > 0) {
    $oov_word{$_} ++;
  }
}
print STDERR "## LOG ($0): lexicon input is done ...\n";

print STDERR "## LOG ($0): words with oov phones \n";
foreach my $line (keys%oov_word) {
  print STDERR "$line\n";
}
print STDERR "## LOG ($0): oov phones\n";
foreach my $phone (keys%oov_phone_list) {
  print STDERR "$phone\n";
}
