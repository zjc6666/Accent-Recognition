#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);


my $numArgs = scalar @ARGV;
if ($numArgs != 1) {
  die "\nExample: cat lex.txt | $0 lex2.txt \n\n";
}
my ($lex_file) = @ARGV;

# begin sub
sub NormalizePhones {
  my ($s) = @_;
  my @A = split(/\s+/, $$s);
  $$s = join(" ", @A);
}
#
sub LoadVocab {
  my ($dict_file, $vocab) = @_;
  open(F, "$dict_file") or die;
  while(<F>) {
    chomp;
    m/(\S+)\s+(.*)/g or next;
    my ($word, $phones) = ($1, $2);
    NormalizePhones(\$phones);
    my $entry = sprintf("%s\t%s", $word, $phones);
    # print "$entry\n";
    $$vocab{$entry} ++;
  }
  close F;
}
# end sub
my %vocab = ();
LoadVocab($lex_file, \%vocab);
print STDERR "## LOG ($0): done with original lexicon ...\n";
print STDERR "## LOG ($0): stdin expected ...\n";
my %word_entry_added = ();
while(<STDIN>) {
  chomp;
  m/(\S+)\s+(.*)/g or next;
  my ($word, $phones) = ($1, $2);
  NormalizePhones(\$phones);
  my $entry = sprintf("%s\t%s", $word, $phones);
  if (not exists $vocab{$entry}) {
    $vocab{$entry} ++;
    $word_entry_added{$entry} ++;
    # print "$entry\n";
  }
}
print STDERR "## LOG ($0): stdin ended ...\n";
foreach my $entry (keys%vocab) {
  print "$entry\n";
}
my $num = scalar keys%word_entry_added;
print STDERR "## LOG ($0): '$num' of words have been merged ...\n";
