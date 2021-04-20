#!/usr/bin/perl -w
use strict;
use utf8;
use open qw(:std :utf8);

# begin sub
sub isEmptyUtterance {
  my ($s) = @_;
  $s =~ s/\s+//g;
  return 1 if($s =~ /^$/);
  return 0;
}
sub CleanUtterance {
  my ($s) = @_;
 #  print STDERR "before cleaning = $$s\n";
  $$s =~ s/<[sxc]\/>//g;
  $$s =~ s/\([^ ]+\)//g;
  $$s =~ s#\-\-empty\-\-##g;
  $$s =~ s/\#//g;
  $$s =~ s/[_\-]/ /g;
  $$s =~ s/[\[\]]//g;
 # print STDERR "after cleaning = $$s\n";
}
sub UtteranceFilterable {
  my ($s) = @_;
  if ($s =~ /^$/g) {
    return 1;
  }
  if($s =~ /\-\-empty\-\-/) {
    # print STDERR "empty utterance = $s\n";
    return 1;
  }
  if ($s =~ /^\([^\(]+\)$/) {
    print STDERR "utterance with only noncontent words = $s\n";
    return 1;
  }
  return 0;
}
# end sub


print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
  chomp;
  m/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/g or next;
  my ($spkid, $wavid, $start, $end, $text) = ($1, $2, $3, $4, $5);
  # print STDERR "text=$text\n";
  CleanUtterance(\$text);
  if(isEmptyUtterance($text) == 1) {
    next;
  }
  if(UtteranceFilterable($text) == 1) {
    next;
  }
  print "$spkid $wavid $start $end $text\n";
}
print STDERR "## LOG ($0): stdin ended ...\n";
