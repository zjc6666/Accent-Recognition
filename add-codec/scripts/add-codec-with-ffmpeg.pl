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
  #my $selected_index = GetRandomNum(1000);
  #if (0 == $selected_index % 2) {
  #  #print "The number $selected_index is even\n";    # There is no remainder
  #  print "$wavid $wav_rspecifier\n";
  #  next
  #} else {
  #  #print "The number $selected_index is odd\n";     # There is a remainder (of 1)
  #}
  
  my $codec_full = $codecList[$index];
  # print STDERR "## DEBUG1 $codec_full\n";
  my @codec_parts = split('-f', $codec_full);
  # print STDERR "## DEBUG2 @codec_parts\n";

  if(IsNormalWavFile($wav_rspecifier) == 1) {
    $wav_rspecifier = "/home4/hhx502/w2019/ffmpeg_source/bin/ffmpeg -nostats -loglevel error -f wav $wav_rspecifier  -ac 1 -ar 8000 -sample_fmt s16  $codecList[$index]  pipe:1| /home4/hhx502/w2019/ffmpeg_source/bin/ffmpeg -nostats -loglevel error -f $codec_parts[1] -i pipe:0 -ar 16000 -f wav pipe:1 |";
  } else { 
    # ffmpeg=/home4/hhx502/w2019/ffmpeg_source/bin/ffmpeg;  sox -t wav /data/users/hhx502/seame/phasei/original/conversation/01nc01fbx_0101/01nc01fbx_0101.wav -t wav - trim 1423.51 1.90| $ffmpeg -nostats -loglevel error -f wav -i pipe:0 -ac 1 -ar 8000 -sample_fmt s16 -b:a 7.7k  -c:a libopus -f ogg    pipe:1 | ffmpeg -y -f ogg -i pipe:0  -f wav -ar 8000 pipe:1 >./test.wav
    #
    
    #my $codec_full = $codecList[$index];
    #my @codec_parts = split('-f', $codec_full);
    #print "$codec_parts[1]";
    #print $codec_full;
    #print $codec_parts[0];
    $wav_rspecifier = "$wav_rspecifier /home4/hhx502/w2019/ffmpeg_source/bin/ffmpeg -nostats -loglevel error -f wav -i pipe:0 -ac 1 -ar 8000 -sample_fmt s16 $codecList[$index]  pipe:1| /home4/hhx502/w2019/ffmpeg_source/bin/ffmpeg -nostats -loglevel error -y -f $codec_parts[1] -i pipe:0 -f wav -ar 8000 pipe:1 |";
  }
  print "$wavid $wav_rspecifier\n";
}
print STDERR "## LOG ($0): wav.scp in ended ...\n";
