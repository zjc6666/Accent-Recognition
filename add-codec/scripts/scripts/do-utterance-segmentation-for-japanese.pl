#!/usr/bin/perl -w
use Getopt::Long;
use strict;
use open qw(:std :utf8);

my $numArgs = scalar @ARGV;
my $max_word_len_in_character = 10;
GetOptions("max-word-len|max_word_len" => \$max_word_len_in_character) or die;

if ($numArgs != 1) {
    die "\nExample: cat text | $0 lexicon.txt > segmented-text\n\n";
}

my ($dict) = @ARGV;

# begin sub
sub LoadTable {
    my ($table, $prefixTable,  $infile) = @_;
    open (F, "$infile") or die;
    while(<F>) {
	chomp;
	m/^(\S+)\s*(.*)$/g or next;
	my $w = $1;
	$$table{$w} ++;
	my @A = split(//, $w);
	print STDERR "word=$w\n";
	$w = "";
	for(my $i = 0; $i < scalar @A; $i ++) {
	  $w .= $A[$i];
	  if(not exists $$prefixTable{$w}) {
	    $$prefixTable{$w} = int(0);
	  }
	  if($i == scalar @A -1) {
	    $$prefixTable{$w} ++;
	  }
	  ## print "$w\t$$prefixTable{$w}\n";
	}
    }
    close F;
    if(0) {
      foreach my $prefix (keys%$prefixTable) {
	print STDERR "$prefix\t$$prefixTable{$prefix}\n";
      }
    }
}
sub LoadPositionDict {
  my ($table, $infile) = @_;
  open(F, "$infile") or die;
  while(<F>) {
    chomp;
    my @A = split(//);
    for(my $i = 0; $i < scalar @A; $i ++) {
      my $array;
      if(not exists $$table{$A[$i]}) {
	my @B = (0, 0, 0, 0);
	$$table{$A[$i]} = \@B;
      } 
      $array = $$table{$A[$i]};
      if(scalar @A == 1) {
	$$array[0] ++;
      } else {
	if($i ==0) {  ## begin
	  $$array[1] ++;
	} else {
	  if($i == scalar @A -1) {  ## end
	    $$array[3] ++;
	  } else {
	    $$array[2] ++;
	  }
	}
      }
    }
  }
  close F;
 if(0) {
   foreach my $c (keys%$table) {
     print STDERR "$c\t";
     my $array = $$table{$c};
     print STDERR join(" ", @$array), "\n";
   }
 } 
}
#
sub NewPath{
  my ($NBest, $utt, $words, $score) = @_;
  my @A = ($utt, $words, $score);
  push @$NBest,\@A;
}
#
sub DoSegmentation {
  my ($wordVocab, $prefixVocab, $posVocab, $NBest) = @_;
  for(my $i = 0; $i < scalar @$NBest; $i ++) {  # we are going to segment for each case
    my $path = $$NBest[$i];
    ## die "path=", scalar @$path, "\n";
    my ($utt, $words, $score) = @$path; 
    ## die "utt=", join(" ", @$utt), "\n";
    while(scalar @$utt > 0 ) {
      my @wholeWords = ();
      my @wholePos = ();
      my $word = "";
      my $pos = 0;
      while($pos < scalar @$utt) {
	my $prev = $word;
	$word .= $$utt[$pos];
	if(not exists $$prefixVocab{$word}) {
	  $word = $prev;
	  last;
	}
	if($$prefixVocab{$word} > 0) {
	  push @wholeWords, $word;
	  push @wholePos, $pos;
	}
	$pos ++;
      }
      if($pos > 0) {  # probably an in-vocabulary word
	if($$prefixVocab{$word} > 0) { # definitely an in-vocabulary word
	  push @$words, $word;
	  splice(@$utt, 0, $pos);  # remove the characters belong to the word
	} else {  # we find a sequence of character, where each characters of the sequence are in the character set,
# but the sequence does not.
	  if(scalar @wholeWords > 0) {
	    $word = pop @wholeWords;
	    print STDERR "##: we find a word ($word) from the subsequence ...\n";
	    $pos = pop @wholePos;
	    push @$words, $word;
	    splice(@$utt, 0, $pos+1);
	  } else {
	    print STDERR "## WARNING: oov word: $word\n"; 
	    push @$words, $word;
	    splice(@$utt, 0, $pos);
	  }
	}
      } else {
	$word = $$utt[$pos]; $pos ++;
	while($pos < scalar @$utt) {
	  my $c = $$utt[$pos];
	  my $posStat = $$posVocab{$c};
	  if(defined $posStat && $$posStat[0] == 0 && $$posStat[1] == 0) {
	    $word .= $c;
	  } else {
	    last;
	  }
	  $pos ++;
	}
	print STDERR "## WARNING: oov word: $word\n";
	push @$words, $word;
	splice(@$utt, 0, $pos);
      }
    }
  }
}
# end sub
my %vocab = ();
my %prefixVocab = ();
LoadTable(\%vocab, \%prefixVocab, $dict);
my %posVocab = ();
LoadPositionDict(\%posVocab, $dict);
print STDERR "## LOG ($0): text in started ...\n";
while(<STDIN>) {
    chomp;
    s/\s+//g;   # remove all whitespace
    my @A = split(//);
    print STDERR "$_\n";
    my @B = ();
    my @NBest = ();
    NewPath(\@NBest, \@A, \@B, 0);
    # die "NBest size=", scalar @NBest, "\n";
    DoSegmentation(\%vocab, \%prefixVocab, \%posVocab, \@NBest);
    for(my $i = 0; $i < scalar @NBest; $i ++) {
      my $array = $NBest[$i];
      my ($utt, $words, $score) = @$array;
      print join(" ", @$words), "\n";
    }
}
print STDERR "## LOG ($0): text in done ...\n";