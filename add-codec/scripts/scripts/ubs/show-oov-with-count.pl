#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);
use Getopt::Long;

# begin sub
sub InsertVocab {
  my ($vocab, $word, $pron) = @_;
  $pron =~ s:\s+: :g; $pron =~ s:^\s+::g; $pron =~ s:\s+$::g; 
  if (exists $$vocab{$word}) {
    my $pronVocab = $$vocab{$word};
    if (not exists $$pronVocab{$pron}) {
       $$pronVocab{$pron} ++;
    }
  } else {
    my %temp = ();
    my $pronVocab = $$vocab{$word} = \%temp;
    $$pronVocab{$pron} ++;
  }
}
sub LoadVocab {
  my ($inFile, $vocab) = @_;
  open (F, "$inFile") or die;
  while(<F>) {
    chomp;
    m:^(\S+)\s*(.*)$:g or next;
    my ($word, $pron) = ($1, $2);
    InsertVocab($vocab, $word, $pron);
  }
  close F;
}
# end sub

my $from = 1;
GetOptions("from=i" => \$from) or die;
my $numArgs = scalar @ARGV;
if ($numArgs != 1) {
  my $example = <<EOF;

 # from: determine the location of the first world to check for each input line,
 #       this is useful in case of dealing with kaldi format text (default 1).
 # By Haihua Xu TLatNTU.

 Usage example: cat text | $0 --from=$from lexicon.txt > oov-count.txt
 
EOF
  die $example;
}

my ($lexFile) = @ARGV;
my %vocab = ();
my %oovVocab = ();
LoadVocab($lexFile, \%vocab);
while(<STDIN>) {
  chomp;
  my @A = split(/\s+/);
  for(my $i = $from - 1; $i < scalar @A; $i++) {
    my $word = $A[$i];
    if(not exists $vocab{$word}) {
      $oovVocab{$word} ++;
    }
  }
}
open(F, "|sort -k2nr") or die;
foreach my $word (keys%oovVocab) {
  print F "$word\t$oovVocab{$word}\n";
}
close F;
