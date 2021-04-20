#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);
use Getopt::Long;

my  $arpa_ngram_file = "";
my  $dict_file = "";
my  $do_word_segmentation;
my  $test_ngram_lm_scoring;
my  $nbest = 1000;
GetOptions("arpa-ngram-file|arpa_ngram_file=s", \$arpa_ngram_file,
	   "dict_file|dict-file=s", \$dict_file,
	   "do-word-segmentation|do_word_segmentation", \$do_word_segmentation,
	   "test-ngram-lm-scoring|test_ngram_lm_scoring", \$test_ngram_lm_scoring,
	   "nbest", \$nbest) or die "## ERROR ($0): failed to get options\n";
my $numArgs = scalar @ARGV;
my $usage=<<"EOF";
 
# decompose out-of-vocabulary word into a sequence of subwords that
# are contained in a specified dictionary. For details, please refer
# to somewhere in stackoverflow.
e.g.: 

cat text | $0  --dict-file=my_dict.txt  > new_text

[options]:
 --arpa-ngram-file=[arpa_ngram_file] 
 --dict-file=[dict_file]
 --do-word-segmentation               # both dict_file and arpa_ngram_file should be provided
 --test-ngram-lm-scoring              # arpa_ngram_file should be provided
 --nbest                              # (default=$nbest)

By Haihua Xu, TL\@NTU, 2019.

EOF
if ($numArgs == 0) {
  print STDERR $usage;
}

# begin sub
## load ngram component
sub  GetWordNgram {
  my ($array, $ngram, $word_ngram) = @_;
  $$word_ngram = "";
  for(my $i = 0; $i < $ngram; $i ++) {
    if ($i==0) {
      $$word_ngram = $$array[$i];
    } else {
      $$word_ngram .= ' ' . $$array[$i];
    }
  }
}
#
sub LoadNGram {
  my ($fpointer, $ngram, $vocab, $line) = @_;
  while(<$fpointer>) {
    chomp;
    $$line = $_;
    if(/^\-\d+(?:\.\d+)?/) {
      my @A = split(/\s+/);
      my @parameter = ();
      push @parameter, shift @A;
      my $word_ngram = "";
      GetWordNgram(\@A, $ngram, \$word_ngram);
      for(my $i = 0; $i < $ngram; $i ++) {  # remove the word sequence
	shift @A;
      }
      my $backoff = 0.0;
      if(scalar @A > 0) {
	$backoff = shift @A;
      }
      push @parameter, $backoff;
      $$vocab{$word_ngram} = \@parameter;
      if (scalar @A != 0) {
	die "## ERROR (LoadNGram, $0): unexpected line '$$line'\n";
      }
    } else {
      return;
    }
  }
}
#
sub LoadArpaNgram {
  my ($arpa_ngram, $inFile) = @_;
  @$arpa_ngram = ();
  open(F, "$inFile") or die "## ERROR ($0): cannot open ngram file '$inFile'\n";
  print STDERR "## LOG ($0): loading arpa-ngram started ...\n";
  my $ngram_index = 0;
  my $N = 0;
  while(<F>) {
    chomp;
    my $line = $_;
    if(/^\\data\\/) {
      my @info = ();
      chomp($line = <F>);
      while($line =~ /^ngram\s+(\d+)=(\d+)\s*/) {
	my @A = ();
	push @A, $1;
	push @A, $2;
	push @info, \@A;
	chomp($line = <F>);
      }
      $N =scalar @info;
      if ($N <= 0) {
	die "## ERROR ($0): an empty arpa-ngram file '$inFile' ?\n";
      }
      push @$arpa_ngram, \@info;
    }
    if($line =~ /^\\1\-grams:/) {
      my %vocab = ();
      LoadNGram(\*F, 1, \%vocab, \$line);
      my $ngram_num = keys%vocab;
      my $info = $$arpa_ngram[0];
      if($ngram_num != $$info[0][1]) {
	die "## ERROR (LoadArpaNgram): mismatched ngram '$ngram_num' <> '$$info[0][1]'\n";
      }
      push @$arpa_ngram, \%vocab;
      $ngram_index ++;
    }
    if($ngram_index < $N && $line =~ /^\\2\-grams:/) {
      my %vocab = ();
      LoadNGram(\*F, 2, \%vocab, \$line);
      # sanity checking
      my $ngram_num = keys%vocab;
      my $info = $$arpa_ngram[0];
      if($ngram_num != $$info[1][1]) {
	die "## ERROR (LoadArpaNgram#2): mismatched ngram '$ngram_num' <> '$$info[1][1]'\n";
      }
      push @$arpa_ngram, \%vocab;
      $ngram_index ++;
    }
    if($ngram_index < $N && $line =~ /^\\3\-grams:/) {
      my %vocab = ();
      LoadNGram(\*F, 3, \%vocab, \$line);
      # sanity checking
      my $ngram_num = keys%vocab;
      my $info = $$arpa_ngram[0];
      if($ngram_num != $$info[2][1]) {
	die "## ERROR (LoadArpaNgram#3): mismatched ngram '$ngram_num' <> '$$info[2][1]'\n";
      }
      push @$arpa_ngram, \%vocab;
      $ngram_index ++;
    }
    if($ngram_index < $N && $line =~ /^\\4\-grams:/) {
      my %vocab = ();
      LoadNGram(\*F, 4, \%vocab, \$line);
      # sanity checking
      my $ngram_num = keys%vocab;
      my $info = $$arpa_ngram[0];
      if($ngram_num != $$info[3][1]) {
	die "## ERROR (LoadArpaNgram#4): mimatched ngram '$ngram_num' <> '$$info[3][1]'\n";
      }
    }
    ## we ignore higher ngram, any way
  }
  close F;
  print STDERR "## LOG ($0): done with loading arpa-ngram ...\n";
}
sub LoadVocab {
  my ($vocab, $inFile) = @_;
  open(F, "$inFile") or die "## ERROR ($0): cannot open dict '$inFile'\n";
  while(<F>) {
    chomp;
    m/(\S+)\s*(.*)\s*$/g or next;
    my ($word, $pron) = ($1, $2);
    if ($pron eq "" or $pron =~ /\d+$/) {
	$$vocab{$word} ++;
	next;
    }
    my $entry = sprintf("%s\t%s", $word, $pron);
    my $ref;
    if(not exists $$vocab{$word}) {
      my %v = ();
      $$vocab{$word} = \%v;
      $ref = $$vocab{$word};
    } else {
      $ref = $$vocab{$word};
    }
    $$ref{$entry} ++;
  }
  close F;
}
# 
sub DecomposeWord {
  my ($vocab, $word, $array) = @_;
  @$array = ();
  $word =~ s/\s+//g;
  if($word eq "") {
    return;
  }
  my @A = split(//, $word);
  my $prefix = "";
  for(my $i = 0; $i < scalar @A; $i ++) {
    $prefix .= $A[$i];
#    next if(not exists $$vocab{$prefix});  # skip
    push @$array, $prefix;
    # print STDERR "prefix=$$array[$i]\n";
  }
  # my $length = scalar @A - 1;
  # if($$array[$length] ne $word) {
  #  die "## ERROR ($0): '$$array[$length]' <> '$word'\n";
  # }
}
# 
sub CopyList {
  my ($sarray, $tarray) = @_;
  @$tarray = ();
  for(my $i = 0; $i < scalar @$sarray; $i ++) {
    push @$tarray, $$sarray[$i];
  }
}
#
sub DumpSample {
  my ($matrix, $info) = @_;
  print "\n$info\n";
  for(my $i = 0; $i < scalar @$matrix; $i ++) {
    my $row_vector = $$matrix[$i];
    my $sample = $$row_vector[0];
    my $score = $$row_vector[1];
    print join(" ", @$sample), " $score\n";
  }
  print "\n\n";
}
#
sub Insert2Nbest {
  my($matrix, $nbest, $result) = @_;
  my $row_num = scalar @$matrix;
  my $N = $row_num;
  $row_num --;
  while($row_num >= 0) {
    my $vector = $$matrix[$row_num];
    if($$vector[1] < $$result[1]) {
      $row_num --;
    } else {
      last;
    }
  }
  # DumpSample($matrix, "before insertion");
  if($N != 0) {
    splice @$matrix, $row_num+1, 0, $result;
  } else {
    push @$matrix, $result;
  }
  # DumpSample($matrix, "after insertion");
  if($N+1 > $nbest) {
    pop @$matrix;
  }
}
#
sub ComposeWord {
  my ($ArpaNgram, $vocab, $original_word, $word,  $vector, $matrix, $nbest) = @_;
  my @A = ();
  DecomposeWord($vocab, $word, \@A);
  print STDERR "word_after_decomposition='$word'\n";
  my $len = scalar @A;
  for(my $i = 0; $i < $len; $i ++) {
    my $token = $A[$i];
    if(exists $$vocab{$token}) {
      push @$vector, $token;
      my $prefix = join("", @$vector);
      if($prefix eq $original_word) {  ## vector is a successful decomposition of the present word
	my @array = ();
	CopyList($vector, \@array);
	my $score = ScoreUtterance($ArpaNgram, join(" ", @array));
	my @result = ();
	push @result, \@array;
	push @result, $score;
	Insert2Nbest($matrix, $nbest, \@result);
	# push @$matrix, \@array; ## keep the present decomposition
	return;
      }
      my $suffix = $word;
      $suffix =~ s/^$token//;
      my @array = ();
      CopyList($vector, \@array);
      # print STDERR "word=$word, prefix=$prefix, suffix_word=$suffix\n";
      # print STDERR "vector=", join(" ", @$vector), "\n";
      ComposeWord($ArpaNgram, $vocab,  $original_word, $suffix, $vector, $matrix, $nbest);
      pop @array;
      CopyList(\@array, $vector);
    }
  }
}
# simple scoring method
sub GetScore {
  my ($array) = @_;
  my $score = 0;
  my  $n = scalar @$array;
  for(my $i = 0; $i < $n; $i ++) {
    $score += length($$array[$i]) - 1;
  }
  $score /= $n*$n;
  return $score;
}
#
sub LookupProb {
  my ($ArpaNgram, $history, $word) = @_;
  my $ngram = scalar @$ArpaNgram - 1;
  my $unk_word = "<unk>";
  my $unk_logprob = -100;
  my $vocab = $$ArpaNgram[1];
  # foreach my $word (keys%$vocab) {
  #   print STDERR "word=$word\n";
  # }
  if((not exists $$vocab{$word}) && (exists $$vocab{$unk_word})) {
    $word = $unk_word;
  }
  if(scalar @$history == 0) { # unigram
    if(exists $$vocab{$word}) {
      my $prob = $$vocab{$word};
      push @$history, $word;
      # print STDERR "word='$word', logprob='$$prob[0]'\n";
      return $$prob[0];
    }
    # print STDERR "word='$word', logprob='$unk_logprob'\n";
    return $unk_logprob; ## uknown word log likelihood mass
  }
  my $history_length = scalar @$history;
  if($history_length >= $ngram) {
      shift @$history;
      $history_length --;
    # die "## LOG (LookupProb): history length:'$history_length' should be smaller  than ngram: '$ngram'\n";
  }
  if(not exists $$vocab{$word}) {  # word does not exist at all
    @$history = ();    # now, no history for the next word
    # print STDERR "word='$word', logprob='$unk_logprob'\n";
    return $unk_logprob; ## uknown word
  }
  push @$history, $word;
  $history_length ++;
  $vocab = $$ArpaNgram[$history_length];  # get corresponding n-gram
  my $word_ngram = "";
  GetWordNgram($history, $history_length, \$word_ngram);
  if(exists $$vocab{$word_ngram}) { # we find the complete n-gram
     my $prob = $$vocab{$word_ngram};
     if($history_length >= $ngram) {
       shift @$history;  # remove the oldest history word
     }
     # print STDERR "word='$word', logprob = '$$prob[0]'\n";
     return $$prob[0];
  }
  # we are doing backoff
  while( (not exists $$vocab{$word_ngram}) &&  $history_length - 1 > 0) {
    shift @$history;  # remove the oldest history word
    $history_length --;
    GetWordNgram($history, $history_length, \$word_ngram);
    $vocab = $$ArpaNgram[$history_length];
  }
  my $prob = $$vocab{$word_ngram};
  # print STDERR "word='$word', logprob='$$prob[0]'\n";
  return $$prob[0] + $$prob[1];
}
#
sub ScoreUtterance {
  my ($ArpaNgram, $text) = @_;
  my $ngram = scalar @$ArpaNgram - 1;
  if($ngram <= 0) {
    die "## ERROR (ScoreUtterance): empty ngram ...\n";
  }
  my $score = -1.0e10;
  my @words = split(/\s+/, $text);
  my $N = scalar @words;
  if ($N == 0) {
    print STDERR "## WARNING (ScoreUtterance): empty utterance \n";
    return $score;
  }
  # add boundary token at the beginning
  # if($words[0] ne "<s>") {
  #  unshift @words, "<s>";
  #  $N ++;
  # }
  # add boundary token in the end
  if ($words[$N -1] ne "</s>") {
    push @words, "</s>";
    $N ++;
  }
  # now we are doing rescoring
  my @history = ();
  my $probability = 0.0;
  for(my $i = 0; $i < $N; $i ++) {
    $probability += LookupProb($ArpaNgram, \@history, $words[$i]);
  }
  return $probability;
}
##  do word segmentation
sub DoWordSegmentation {
  my ($vocab, $ArpaNgram, $nbest) = @_;
  my $counter = 0;
  print STDERR "## LOG ($0): stdin expected (nbest=$nbest) ...\n";
  while(<STDIN>) {
    chomp;
    $counter ++;
    if($counter <= 1) {
      print STDERR "## LOG ($0): stdin is seen ...\n";
    }
    m/(\S+)\s*(.*)$/g or next;
    my ($word) = ($1);
    my @Matrix = ();
    my @Vector = ();
    ComposeWord($ArpaNgram, $vocab,  $word, $word, \@Vector, \@Matrix, $nbest);
   # for(my $i = 0; $i < 3 && $i <scalar @Matrix; $i ++) {
    my $number=scalar @Matrix;
    print STDERR "## LOG ($0): $number\n";
    for(my $i = 0; $i < 1 && $i <scalar @Matrix; $i ++) {
      my $row_vector = $Matrix[$i];
      my $result = $$row_vector[0];
      # print "$word ", join(" ", @$result), " $$row_vector[1]\n\n";
      print "$word ", join(" ", @$result), " \n";
    }
  }
}
# test ngram-lm scoring on utterances
sub TestNgramLmScoring {
  my ($ArpaNgram) = @_;
  while(<STDIN>) {
    chomp;
    my $score = ScoreUtterance($ArpaNgram, $_);
    print "'$_' $score\n";
  }
}
# end sub

my %vocab = ();
if ($dict_file ne "") {
  LoadVocab(\%vocab, $dict_file);
}
my @ArpaNgram;
if($arpa_ngram_file ne "") {
  LoadArpaNgram(\@ArpaNgram, $arpa_ngram_file);
}
if ($do_word_segmentation) {
  if($arpa_ngram_file ne "" && $dict_file ne "") {
    DoWordSegmentation(\%vocab, \@ArpaNgram, $nbest);
    exit(0);
  }
  die "## ERROR ($0): dict & ngram language models should be given\n";
}
if ($test_ngram_lm_scoring) {
  if($arpa_ngram_file ne "") {
    TestNgramLmScoring(\@ArpaNgram);
    exit(0);
  }
  die "## ERROR ($0): arpa_ngram_file should be provided\n";
}
