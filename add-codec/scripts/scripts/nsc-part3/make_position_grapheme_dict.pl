#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);
use Getopt::Long;

my $ignore_phone_set = "-;_";
GetOptions("ignore-phone-set|ignore_phone_set=s" => \$ignore_phone_set) || die;
my $numArgs = scalar @ARGV;

if($numArgs != 1) {
  die "\nUsage: cat wordlist.txt| $0 [--ignore-phone-set=$ignore_phone_set] mandarin-syllable-lexicon.txt > grapheme-lexicon.txt\n\n";
}

my ($man_syllable_dict) = @ARGV;

# begin sub
sub LoadVocab{
  my ($dict_file, $vocab) = @_;
  open(F, "$dict_file") or die;
  while(<F>) {
    chomp;
    m/(\S+)\s+(.*)/g or next;
    my ($word, $phones) = ($1, $2);
    my $pron_ref = "";
    if(exists $$vocab{$word}) {
      $pron_ref = $$vocab{$word};
    } else {
      my @A;
      $$vocab{$word} = \@A;
      $pron_ref = $$vocab{$word};
    }
    push @$pron_ref, $phones;
  }
  close F;
}
#
sub isMandarinSyllableSequence {
  my ($word, $vocab, $pron) = @_;
  return 0 if($word =~ m/[<>]/);
  my @A = split(/[\-_]/, $word);
  @$pron = ();
  for(my $i = 0; $i < scalar @A; $i ++) {
    my $w = $A[$i];
    return 0 if(not exists $$vocab{$w});
    my $ref = $$vocab{$w};
    push @$pron, @$ref[0];   # we just simply get the first pronunciation
  }
  return 1;
}
# end sub
my %vocab = ();
LoadVocab($man_syllable_dict, \%vocab);
my @A = split(/[;, ]/, $ignore_phone_set);
for(my $i = 0; $i < scalar @A; $i ++) {
  my $word = $A[$i];
  $vocab{$word} = $word;
}
print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
  chomp;
  my @pron;
  if(isMandarinSyllableSequence($_, \%vocab, \@pron) == 1) {
    my $phones = join(" ", @pron);
    print "$_\t$phones\n";
  } 
 {
    next if(/[<>]/);  # we are ignoring those non-content words that kaldi normally uses, such as <noise>, <v-noise>, etc.
    my $to_be_split_word = $_;
    $to_be_split_word =~ s/[\'\-_]//g;
    if($to_be_split_word =~ /[^a-z]/) {
      print STDERR "word '$_' contains unknown letter...\n";
      next;
    } 
    next if ($to_be_split_word =~ /^$/);
    my @pron = split(//, $to_be_split_word);
    # add language suffix '_eng'
    for(my $i = 0; $i < scalar @pron; $i ++) {
	$pron[$i] = $pron[$i] . "_eng";
    }
    $pron[0] = $pron[0] ."_"."WB";
    my $len = scalar @pron;
    if($len > 1) {
      $pron[$len-1] = $pron[$len-1] . "_" . "WB";
    }
    my $phones = join(" ", @pron);
    print ("$_\t$phones\n");
  }
}
print STDERR "## LOG ($0): stdin ended ...\n";
