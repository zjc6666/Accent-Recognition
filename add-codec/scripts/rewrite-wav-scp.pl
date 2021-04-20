#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);

my $numArg = scalar @ARGV;

if ($numArg != 1) {
  die "\nUsage Example: cat segments | $0 wav.scp data\n\n";
}
my ($wavscp) = @ARGV;

# begin sub
sub LoadVocab {
  my ($filename, $vocab) = @_;
  open (F, "$filename") or die;
  while(<F>) {
    chomp;
    m/(\S+)\s+(.*)/g or next;
    $$vocab{$1} = $2;
  }
  close F;
}
sub IsNormalWavFile {
  my ($filename) = @_;
  my @A = split(/\s+/, $filename);
  return 0 if @A > 1;
  return 1;
}
# end sub

my %vocab = ();
# load wavscp file to the hash table for 
# the next-step indexing using the wavid 
# from segments file
LoadVocab($wavscp, \%vocab);

# open(F, ">$tgtdir/wav.scp") or die "## ERROR ($0): cannot open file '$tgtdir/wav.scp' to write\n";
print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
  chomp;
  my @A = split(/\s+/);
  die if scalar @A != 4;
  my $wavId = $A[1];
  my $segId = $A[0];
  my $start_time = $A[2];
  my $dur = $A[3] - $A[2];
  $dur = sprintf("%.2f", $dur);
  die "## ERROR ($0): illegal segment line $_ \n" if $dur <= 0;
  die "## ERROR ($0): no wavid '$wavId' found in the specified wav.scp\n" 
  if not exists $vocab{$wavId};
  my $wav_rspecifer = $vocab{$wavId};
  if(IsNormalWavFile($wav_rspecifer) == 1) {  ## here normal wave file means a single wave file without pipe operation
    $wav_rspecifer =  "sox -t wav $wav_rspecifer -t wav -r 8000 - trim $start_time $dur|";
  } else {  ## its a pipe-based specifier
    $wav_rspecifer = "$wav_rspecifer sox -t wav - -t wav -r 8000 - trim $start_time $dur|";
  }
  print "$segId $wav_rspecifer\n";
}
print STDERR "## LOG ($0): stdin ended ...\n";
