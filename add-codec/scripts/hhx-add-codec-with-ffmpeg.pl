#!/usr/bin/perl -w 
use strict;
use utf8;
use open qw(:std :utf8);

my $numArgs = scalar @ARGV;
if($numArgs != 1) {
  die "\n\nExample cat wav.scp | $0 codec-list.txt > new_wav.scp\n\n";
}

my ($codecListFile) = @ARGV;
srand(777);

# begin sub
sub TrailSpace {
  my ($s) = @_;
  $$s =~ s/^ +//;
  $$s =~ s/ +$//;
}
sub LoadCodecList {
  my ($array, $filename) = @_;
  open (F, "$filename") or die;
  while(<F>) {
    chomp;
    TrailSpace(\$_);
    push @$array, $_;
  }
  close F;
}
sub IsNormalWavFile {
  my ($filename) = @_;
  my @A = split(/\s+/, $filename);
  return 0 if @A > 1;   # pipe
  $filename =~ s/ +$//;
  return 1 if($filename =~ /\|$/);
  return 0;
}
sub GetRandomNum {
  my ($maxNum) = @_;
  my $retNum = rand($maxNum);
   $retNum = int($retNum);
  die if $retNum >= $maxNum;
  return $retNum;
}
# end sub
my @codecList = ();
LoadCodecList(\@codecList, $codecListFile);
if(scalar @codecList <= 0) {
  die "## ERROR ($0): empty codec list file '$codecListFile'\n";
}
my $codecNum = scalar @codecList;
print STDERR "## LOG ($0): wav.scp in expected ...\n";
while(<STDIN>) {
  chomp;
  m/(\S+)\s+(.*)$/g or next;
  my ($wavid, $wav_rspecifier) = ($1, $2);
  my $index = GetRandomNum($codecNum);
  if(IsNormalWavFile($wav_rspecifier) == 1) {
    $wav_rspecifier = "ffmpeg -nostats -loglevel error -f wav $wav_rspecifier  -ac 1 -ar 8000 -sample_fmt s16  $codecList[$index] -f wav    pipe:1|ffmpeg -nostats -loglevel error -f wav -i pipe:0 -ar 16000 -f wav pipe:1 |";
  } else {
    $wav_rspecifier = "$wav_rspecifier ffmpeg -nostats -loglevel error -f wav -i pipe:0 -ac 1 -ar 8000 -sample_fmt s16 $codecList[$index] -f wav    pipe:1| ffmpeg -nostats -loglevel error -f wav -i pipe:0 -ar 16000 -f wav pipe:1 |";
  }
  print "$wavid $wav_rspecifier\n";
}
print STDERR "## LOG ($0): wav.scp in ended ...\n";
