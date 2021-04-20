#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);
use Getopt::Long;

my $sample_num = 100;
my $sample_utt_file = "";
my $srand = 777;
my $play;
GetOptions("sample_num|sample-num=i", \$sample_num,
	   "sample_utt_file|sample-utt-file=s", \$sample_utt_file,
	   "srand=i", \$srand,
	   "play", \$play) or die;
srand($srand);
my $usage =<<"EOF";
  
  # this script is meant to be checking the sanity of the kaldi data, by
  # randomly selecting specified number of wav files and their corresponding text
  # for human to listen and check.
  # This is particularly useful when we add noise to the data and want to see
  # if the effectiveness of the operation is what we expected.
  # It is also useful for data preparation.
  # But, care should be taken for that it needs kaldi support for dumping the wave
  # segments. As a result, please run '. path.sh' first. It also possibly needs
  # sox, ffmpeg etc.
  
  $0 [options]  <source_kaldi_data_dir> <target_kaldi_data_dir>   
  [options]:
  --sample-num              # subsampling number of files (default=$sample_num)
  --sample-utt-file         # user specified utterance list file to check
  --srand                   # srand number (default=$srand)
  --play                    # play the waves in a specified folder
  e.g.: $0  --sample-num=10  train   for_listening
  # it is going to randomly select 10 utterances from the text file and 
  # dump corresponding wave segment files in 'train' folder to the target folder, 'for_listening'

  by Haihua Xu , TLatNTU, 2019.

EOF
my $user_cmd = "$0 ". join(" ", @ARGV);
if (scalar @ARGV < 1) {
  print STDERR  "$usage\n";
  die "## LOG: $user_cmd\n\n";
}
my ($sdir, $dir);
if(scalar @ARGV == 2) {
  ($sdir, $dir) = @ARGV;
} elsif(scalar @ARGV == 1) {
  $sdir = shift @ARGV;
} else {
  print STDERR  "$usage\n";
  die "## LOG: $user_cmd\n\n";
}

print STDERR "## LOG: $user_cmd\n";
if ($play) {
  PlayWaves($sdir, $sample_num);
  exit 0;
}
DoChecking(\$sdir, \$dir);
# begin sub
sub CollectWaves {
  my ($array, $vocab) = @_;
  foreach my $line (@$array) {
    next if not ($line =~ /wav$/ or $line =~ /WAV$/);
    my $wave = $line;
    $line =~ s/\.wav$//;  $line =~ s/\.WAV$//;
    $line =~ m/(.*)\/([^\/]+)$/g;
    my $waveId = $2;
    next if not defined $waveId;
    $$vocab{$waveId} = $wave;
  }
}
#
sub LoadText {
  my ($textfile, $vocab) = @_;
  open(TXT, "$textfile") or return;
  while(<TXT>) {
    chomp;
    m/(\S+)\s+(.*)/g or next;
    $$vocab{$1} = $_;
  }
  close TXT;
}
#
sub PlayWaves {
  my ($dir, $sample_num) = @_;
  my $waves = `find $dir -name "*.wav"`;
  $waves .= `find $dir -name "*.WAV"`;
  my @A = split(/\s+/, $waves);
  my $wave_num = scalar @A;
  if($wave_num <= 0) {
    print STDERR "## nothing to play ...\n";
    return;
  }
  my %vocab = ();
  CollectWaves(\@A, \%vocab);
  my %uttvocab = ();
  if( -e "$dir/text") {
    LoadText("$dir/text", \%uttvocab);
  }
  my $counter = 0;
  foreach my $waveId (keys%vocab) {
    next if ($counter ++ >= $sample_num);
    my $wavfile = $vocab{$waveId};
    my $text = $uttvocab{$waveId};
    if (defined $text) {
      print "[$text]\n";
    }
    `play $wavfile`;
    if($?) {
      die "## ERROR ($?): failed to play file '$wavfile'";
    }
  }
}
#
sub DoChecking {
  my ($sdir, $dir) = @_;
  $$sdir =~ s/\/$//;
  $$dir =~ s/\/$//;
  foreach my $file (("$$sdir/text", "$$sdir/wav.scp")) {
    if(!-e $file) {
      die "## ERROR ($0): file '$file' expected ...\n";
    }
  }
  `[ -d $$dir ] || mkdir -p $$dir`;
  if(not -w $$dir) {
    die "## ERROR ($0): target folder '$$dir' is not writeable ...\n";
  }
}
#
sub GetSubText {
  my ($dir, $sample_num, $array) = @_;
  open (TXT, "$dir/text") or die "## ERROR ($0): file '$dir/text'cannot open\n";
  my @lines;
  while(<TXT>) {
    chomp;
    push @lines, [ (rand(), $_)] ;
  }
  close TXT;
  @lines = sort { $a->[0] cmp $b->[0] } @lines;
  my $count = 0;
  foreach my $l (@lines) {
    if($count ++ < $sample_num) {
      push @$array, $l->[1];
    }
  }
}
# 
sub GetSelectedUtterance {
    my ($uttlistFile, $array) = @_;
    open (F, "$uttlistFile") or die;
    while(<F>) {
      chomp;
      m/(\S+)\s*(.*)/g or next;
      push @$array, $_;
    }
    close F;
}
#
sub LoadSegments {
  my ($segments, $vocab) = @_;
  open(SEG, "$segments") or die "## ERROR ($0): cannot open file '$segments'\n";
  while(<SEG>) {
    chomp;
    my @A = split(/\s+/, $_);
    next if scalar @A != 4;
    $$vocab{$A[0]} = \@A;
  }
  close SEG;
}
#
sub LoadWavScp {
  my ($wavscp, $vocab) = @_;
  open(WAV, "$wavscp") or die "## ERROR ($0): cannot open file '$wavscp'\n";
  while(<WAV>) {
    chomp;
    m/(\S+)\s+(.*)$/g or next;
    my ($waveId, $wave_rspecifier) = ($1, $2);
    $wave_rspecifier =~ s/\s+ $//;
    $$vocab{$waveId} = $wave_rspecifier;
  }
  close WAV;
}
# end sub
my @selected_utterance = ();
if ($sample_utt_file eq "") {
    GetSubText($sdir, $sample_num, \@selected_utterance);
} else {
    my %table = ();
    my $text_file = "$sdir/text";
    if ( -e $text_file) {
      LoadText($text_file, \%table);
    }
    GetSelectedUtterance ($sample_utt_file, \@selected_utterance);
    if (keys%table) {
      for(my $i = 0; $i < scalar @selected_utterance; $i ++) {
        if(exists $table{$selected_utterance[$i]}) {
	  $selected_utterance[$i] = $table{$selected_utterance[$i]};
	}
      }
    }
}

my %vocab = ();
my %segments = ();
my $hasSegments = 0;
if ( -e "$sdir/segments" ) {
  LoadSegments("$sdir/segments", \%segments);
  $hasSegments = 1;
}
foreach my $utt (@selected_utterance) {
  $utt =~ m/(\S+)\s*(.*)/g or next;
  my ($segId, $text) = ($1, $2);
  my $array;
  my $waveId;
  my @time_boundary = ();
  if ($hasSegments == 1) {
    if(not exists $segments{$segId}) {
      die "## ERROR ($0): no '$segId' does not exist in segments\n";
    }
    $array = $segments{$segId};
    $waveId = $$array[1];
    @time_boundary = ($$array[0], $$array[2], $$array[3]);
  } else {
    $waveId = $segId;
  }
  my $ref;
  if(exists $vocab{$waveId}) {
    $ref = $vocab{$waveId};
  } else {
    my @A = ();
    $vocab{$waveId} = \@A;
    $ref = $vocab{$waveId};
  }
  push @$ref, \@time_boundary;
}
# now, we try to save wave segment into the target folder
my %wave = ();
if(!-e "$sdir/wav.scp") {
  die "## ERROR ($0): '$sdir/wav.scp' file expected ...\n";
}
LoadWavScp("$sdir/wav.scp", \%wave);
foreach my $waveId (keys%vocab) {
  if(not exists $wave{$waveId}) {
    die "## ERROR ($0): '$waveId' does not exist in '$sdir/wav.scp' file\n";
  }
  my $wave_rspecifier = $wave{$waveId};
  my $boundary_array =  $vocab{$waveId};
  foreach my $boundary (@$boundary_array) {
    my $make_wave_cmd = "";
    if(scalar @$boundary > 0) {
      my $tgt_wave_file = "$dir/$$boundary[0]" . ".wav";
      my $start = $$boundary[1];
      my $dur = $$boundary[2] - $$boundary[1];
      if($wave_rspecifier =~ /\|$/) {  # it's a pipe
	$make_wave_cmd = $wave_rspecifier . " sox -t wav - -t wav  $tgt_wave_file  trim $start $dur";
      } else {
	if(($wave_rspecifier =~ /wav$/ or $wave_rspecifier =~ /WAV$/) and 
	   scalar split(/\s+/, $wave_rspecifier) == 1) {  # it's a normal wave file
	  $make_wave_cmd = "sox -t wav $wave_rspecifier -t wav $tgt_wave_file trim $start $dur";
	} else {
	  die "## ERROR ($0): unknown wave specifier '$wave_rspecifier'\n";
	}
      }
    } else { # no time boundary, it is either a single wave file, or a pipeline
      my $tgt_wave_file = "$dir/$waveId" . ".wav";
      if($wave_rspecifier =~ /\|$/) {
	$make_wave_cmd = $wave_rspecifier . " cat - > $tgt_wave_file";
      } else {
	if($wave_rspecifier =~ /wav$/ or $wave_rspecifier =~ /WAV$/ and
	   scalar split(/\s+/, $wave_rspecifier) == 1) { # it's a normal wave file
	  $make_wave_cmd = "cp $wave_rspecifier $tgt_wave_file";
	} else {
	  die "## ERROR ($0): unknown wave specifier '$wave_rspecifier'\n";
	}
      }
    }
    if(system($make_wave_cmd)) {
      die "## ERROR ($0): failed to run command '$make_wave_cmd'\n";
    }
  }
}
# now move the text to the target folder
open(TXT, "|sort -u > $dir/text") or die "## ERROR ($0): failed to open text '$dir/text'\n";
foreach my $line (@selected_utterance) {
  print TXT "$line\n";
}
close TXT;
