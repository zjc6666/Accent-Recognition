#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);

my $numArgs = @ARGV;

if($numArgs != 3) {
  die "\nExample: cat wordlist.txt | $0 dict.txt subset-dict.txt oov-word.txt\n\n";
}
my ($sDictFile, $sSubDictFile, $sOovListFile) = @ARGV;

# begin sub
sub InitWordDict {
  my ($sDictFile, $wordDictVocab) = @_;
  open (F, "$sDictFile") or die "## ERROR (InitWordDict, ", __LINE__, "): cannot open file $sDictFile\n";
  while(<F>) {
    chomp;
    m/(\S+)\s+(.*)/ or next;
    my ($word, $phones) = ($1, $2);
    my @A = split(/\s+/, $phones);
    $phones = join(" ", @A);
    my $dictLine = sprintf("%s\t%s", $word, $phones);
    if (not exists $$wordDictVocab{$word}) {
      my %vocab = ();
      my $ref = $$wordDictVocab{$word} = \%vocab;
      $$ref{$dictLine} ++;
    } else {
      my $ref = $$wordDictVocab{$word};
      $$ref{$dictLine} ++;
    }
  }
  close F;
}
sub CopyWordPron {
  my ($word, $srcVocab, $targetVocab) = @_;
  my $href = $$srcVocab{$word};
  return if not defined $href;
  foreach my $pron (keys %$href) {
    $$targetVocab{$pron} ++;
  }
}
# end sub
my %vocab = ();
InitWordDict($sDictFile, \%vocab);
my %outputWordVocab = ();
open(LEX, "|sort -u >$sSubDictFile") or die "## ERROR ($0): cannot open file $sSubDictFile\n";
open(OOV, "|sort -u >$sOovListFile") or die "## ERROR ($0): cannot open file $sOovListFile\n";
print STDERR "## LOG ($0): stdin expected\n";
while(<STDIN>) {
  chomp;
  m/(\S+)\s*(.*)/g or next;
  my ($word) = $1;
  CopyWordPron($word, \%vocab, \%outputWordVocab);
  if(not exists $vocab{$word}) {
    print OOV "$word\n";
  }
}
print STDERR "## LOG ($0): stdin ended\n";
foreach my $pron (keys%outputWordVocab) {
  print LEX "$pron\n";
}
close LEX;
close OOV;
