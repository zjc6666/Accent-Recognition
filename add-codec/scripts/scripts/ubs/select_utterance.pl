#!/usr/bin/perl
use strict;
use utf8;
use open qw(:std :utf8);
use Getopt::Long;
use Data::Dumper;

my $from = 1;
my $oov_threshold = 30;

GetOptions("from=i" => \$from,
	   "oov-threshold|oov_threshold=i" => \$oov_threshold) or die;
my $usage = <<"EOF";

# Given kaldi text file, we  classify the file into
# three subset files: pure chinese text, mandarin-english-mixed text, and 
# pure english text.
# usage:
  cat text | \
  $0  --oov-threshold=30  <chinese_character_dict.txt> <english_common_word_dict.txt>  <tgtdir>

EOF

my $numArgs = scalar @ARGV;

if ($numArgs != 3) {
  die $usage;
}

my ($cnDictFile, $enDictFile, $tgtdir) = @ARGV;

# begin sub
sub LoadVocab {
  my ($vocab, $dictFile) = @_;
  open(F, "$dictFile") or die;
  while(<F>) {
    chomp;
    m/(\S+)\s*(.*)/g or next;
    $$vocab{$1} ++;
  }
  close F;
}
# 
sub GetOovRate {
  my ($words, $vocab, $count) = @_;
  for(my $i = 0; $i < 3; $i ++) {
    push @$count, 0;
  }
  for (my $i = 0; $i < scalar @$words; $i ++) {
    my $word = lc $$words[$i];
    if($word eq '<unk>') {
      $$count[2] ++;
    } elsif($word =~ /\p{Han}/) {
      if( exists $$vocab{$word}) {
	$$count[0] ++;
      } else {
	$$count[2] ++;
      }
    } else {
      if(exists $$vocab{$word}) {
	$$count[1] ++;
      } else {
	$$count[2] ++;
      }
    }
  }
  my $total = $$count[0] + $$count[1] + $$count[2];
  return 100 if ($total ==0);
  return $$count[2]*100 / $total;
}
#
sub DumpHashKey {
  my ($vocab) = @_;
  foreach my $key (keys%$vocab) {
    print STDERR "key=$key ";
  }
  print STDERR "\n";
}
#
sub ProcessUtterance {
  my ($uttid, $words, $vocab, $outputVocab) = @_;
  my $text = join(" ", @$words);
  my $original_text = $text;
  $text =~  s/(\p{Han})(\p{Han})/ $1 $2 /g;
  $text =~ s/^\s+//; $text =~ s/\s+$//;
  return if ($text =~ /^$/);  # for empty utterance
  @$words =  split(/\s+/, $text);
  my @Count = ();
  my $oovRate = GetOovRate($words, $vocab, \@Count);
  if($oovRate > $oov_threshold) {
    print STDERR "## WARN ($0): skip utterance due to higher oov rate: '$uttid $text'\n";
    return;
  }
  my $utt = "$uttid $original_text";
  my $hash;
  if($Count[0] == 0) {
    if (exists $$outputVocab{"english"}) {
      $hash = $$outputVocab{"english"};
    } else {
      my %v = ();
      $$outputVocab{"english"} = \%v;
      $hash = $$outputVocab{"english"};
    }
    # print STDERR "## DEBUG (", __LINE__, "): see english utterance '$utt'\n";
    $$hash{$utt} ++;
  } elsif($Count[1] == 0) {
    if(exists $$outputVocab{"chinese"}) {
      $hash = $$outputVocab{"chinese"};
    } else {
      my %v = ();
      $$outputVocab{"chinese"} = \%v;
      $hash = $$outputVocab{"chinese"};
    }
    $$hash{$utt} ++;
    # DumpHashKey($hash);
  } else {
    if (exists $$outputVocab{"mix"}) {
      $hash = $$outputVocab{"mix"};
    } else {
      my %v = ();
      $$outputVocab{"mix"} = \%v;
      $hash = $$outputVocab{"mix"};
    }
    $$hash{$utt} ++;
  }
  return int($oovRate);
}
# end sub

my %vocab = ();
LoadVocab(\%vocab, $cnDictFile);
LoadVocab(\%vocab, $enDictFile);

print STDERR "## LOG ($0): stdin expected ...\n";
my $linenum = 0;
my %outputVocab = ();
while (<STDIN>) {
  chomp;
  $linenum ++;
  if($linenum == 1) {
    print STDERR "## LOG ($0): stdin expected ...\n";
  }
  my @A = split(/\s+/);
  my $uttid = shift @A;
  ProcessUtterance($uttid, \@A, \%vocab, \%outputVocab);
}
print STDERR "## LOG ($0): stdin ended ...\n";
`[ -d $tgtdir ] || mkdir -p $tgtdir`;
open(CF, "|sort -k1 > $tgtdir/text_cn") or die;
open (EF, "|sort -k1 > $tgtdir/text_en") or die;
open (MF, "|sort -k1 > $tgtdir/text_mix") or die;
# print Dumper(\%outputVocab);
foreach my $language (keys%outputVocab) {
  print STDERR "## DEBUG (", __LINE__, "): language=$language\n";
  if($language eq "chinese") {
    my $table = $outputVocab{"chinese"};
    foreach my $utterance (keys%$table) {
      # print STDERR "utterance=$utterance\n";
      print CF "$utterance\n";
    }
    close CF;
  } elsif($language eq "english") {
    my $table = $outputVocab{"english"};
    foreach my $utterance (keys%$table) {
      # print STDERR "english utterance = '$utterance'\n";
      print EF "$utterance\n";
    }
    close EF;
  } elsif($language eq "mix") {
    my $table = $outputVocab{"mix"};
    foreach my $utterance (keys%$table) {
      print MF "$utterance\n";
    }
    close MF;
  } else {
    die "## ERROR ($0): unknown language '$language' for utterance '$_'\n";
  }
}
