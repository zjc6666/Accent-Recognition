#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);

# begin sub
sub isEmptyUtterance {
  my ($s) = @_;
  $s =~ s/\s+//g;
  return 1 if($s =~ /^$/);
  return 0;
}
sub CleanUtterance {
  my ($s) = @_;
 #  print STDERR "before cleaning = $$s\n";
  $$s =~ s/<[sxc]\/>//g;
  $$s =~ s/\([^ ]+\)//g;
  $$s =~ s#\-\-empty\-\-##g;
  $$s =~ s/\#//g;
  $$s =~ s/[_\-]/ /g;
  $$s =~ s/[\[\]]//g;
 # print STDERR "after cleaning = $$s\n";
}
sub UtteranceFilterable {
  my ($s) = @_;
  if ($s =~ /^$/g) {
    return 1;
  }
  if($s =~ /\-\-empty\-\-/) {
    # print STDERR "empty utterance = $s\n";
    return 1;
  }
  if ($s =~ /^\([^\(]+\)$/) {
    print STDERR "utterance with only noncontent words = $s\n";
    return 1;
  }
  return 0;
}
#
sub CountOov {
  my ($text, $threshold) = @_;
  my @A = split(/\s+/, $text);
  my $con = 0;
  my $oov = 0;
  for(my $i  = 0; $i < scalar @A; $i ++) {
    my $w = $A[$i];
    if($w =~ /</ || $w =~ />/) {
      $oov ++;
    } else {
      $con ++;
    }
  }
  my $total = $oov + $con;
  if($total == 0) {
    return 1;
  }
  my $oov_rate = 100*$oov / $total;
  if ($oov_rate >= $threshold) {
    return 1;
  }
  return 0;
}
# end sub

my $numArgs = scalar @ARGV;
if($numArgs != 3) {
  print STDERR "\nUsage: cat text | $0 <threshold> usable-uttlis.txt  unusable-uttlist.txt\n\n";
  exit (1);
}
my ($thresh, $usable, $unusable) = @ARGV;
open (USABLE, ">$usable") or die;
open (UNUSABLE, ">$unusable") or die;
print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
  chomp;
  # m/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/g or next;
  # my ($spkid, $wavid, $start, $end, $text) = ($1, $2, $3, $4, $5);
  # print STDERR "text=$text\n";
  m/^(\S+)\s+(.*)/g or next;
  my ($uttid, $text) = ($1, $2);
  # CleanUtterance(\$text);
  if($text eq "") {
    print UNUSABLE "$uttid\n";
  }
  if(CountOov($text, $thresh) == 0) {
    print USABLE  "$uttid\n";
  } else {
    print UNUSABLE "$uttid\n";
  }
  # if(UtteranceFilterable($text) == 1) {
  #  next;
  # }
  # print "$spkid $wavid $start $end $text\n";
}
print STDERR "## LOG ($0): stdin ended ...\n";

close USABLE;
close UNUSABLE;
