#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);
use Getopt::Long;

our $convert_utf16;
our $ignore_speaker;
GetOptions('convert_utf16|convert-utf16' => \$convert_utf16,
           'ignore_speaker|ignore-speaker' => \$ignore_speaker) or die;

# begin sub
sub MakeSpeakerId {
  my ($dataId, $textGridFile, $nFileIndex, $speakerId, $noSpkIndex) = @_;
  $speakerId =~ s:\"::g; $speakerId = lc $speakerId;  $speakerId =~ s:^\s*$::g;
  my ($speakerIndex, $sex);
  if($speakerId eq '') {
    $$noSpkIndex ++;
    $speakerIndex = $$noSpkIndex;
    $speakerId = 'nospk';
    $sex = 'n';
  } else {
    if($speakerId =~ /s(\d+)\-(\S+)/) {
      ($speakerIndex, $sex) = ($1, $2);
      $speakerId = 'spk';
    } else {
      if($speakerId =~/([\D]+)([\d]+)/) {
        $speakerId = '-'.$1;
        $speakerIndex = $2;
	$sex= 'm';
      } else {
        print STDERR "unknown speakerId '$speakerId' in file '$textGridFile'\n";
	$$noSpkIndex ++;
	$speakerIndex = $$noSpkIndex;
        $speakerId = 'nospk';
        $sex = 'n';
      }
    }
  }
  # print "speakerId=$speakerId, speakerIndex=$speakerIndex, sex=$sex\n";
  $speakerId = sprintf("%s%05d%s%03d%s", $dataId, $nFileIndex, $speakerId, $speakerIndex, $sex);
  # print "speakerId=$speakerId\n";
  return $speakerId;
}
sub GetBaseName {
  my ($fileName) = @_;
  $fileName =~ m:(.*)\/([^\/]+$):g;
  $fileName = $2;
  $fileName =~ s:\.[^\.]+$::g;
  return $fileName;
}
sub TextGridCracker {
  my ($textGridFile, $nFileIndex, $dataId, $tgtdir) = @_;
  my $istream = $textGridFile;
  my $is_utf16 = `file $textGridFile | grep -i utf-16`;
  $is_utf16 =~ s/^ +//;
  $is_utf16 =~ s/ +$//g;
  if($is_utf16 !~ /^$/) {
    $istream = "iconv -f utf16 -t utf8 $istream|dos2unix|";
  }
  open(GF, "$istream") or die;
  my $baseName = GetBaseName($textGridFile);
  my $noSpkIndex = 0;
  my $speakerId = '';
  my $startSec = 0; my $endSec = 0;
  my $utterance = '';
  print STDERR "## LOG ($0): proccessing text grid file: $textGridFile ...\n";
  while(<GF>) {
    if(/name\s*=\s*(\S*)/) {
      $speakerId = $1;
      $speakerId = MakeSpeakerId($dataId, $textGridFile, $nFileIndex, $speakerId, \$noSpkIndex);
      # print "speakerId=$speakerId\n";
    }
    if(/xmin\s*=\s*(\S+)/) {
      $startSec = $1;
    }
    if(/xmax\s*=\s*(\S*)/) {
      $endSec = $1;
    }
    if(/text\s*=\s*(.*)/) {
      $utterance = $1; $utterance =~ s:\"::g; $utterance = lc $utterance; $utterance =~ s:^\s*$::g;
      if($utterance ne '' && $endSec - $startSec >= 1.0) {
	$startSec = sprintf("%.2f", $startSec);
	$endSec = sprintf("%.2f", $endSec);
        print "$speakerId $baseName $startSec $endSec  $utterance\n"
      }
    }
  }
  close GF;
}
# end sub
my $numArgs = scalar @ARGV;
if($numArgs != 3) {
  die "\n[Example]: $0 <textgrid-list.txt> <dataId> <tgtdir>\n\n";
}
my ($textGridList, $dataId, $tgtdir) = @ARGV;

open(F, "$textGridList") or die;
my $nFileIndex = 0;
while(<F>) {
  chomp;
  next if(/^\s*$/);
  $nFileIndex ++;
  TextGridCracker($_, $nFileIndex, $dataId, $tgtdir);
}
close F;
