#!/usr/bin/perl
use warnings;
use strict;
use open qw(:std :utf8);
use  Getopt::Long;

my $from = 2;
my $print_warning;
GetOptions("from=i" => \$from,
	   "print_warning|print-warning" => \$print_warning) or die;
my $numArgs = scalar @ARGV;
if ($numArgs != 1) {
    die "\nExample: cat kaldi-format-text | $0 word-transfer-dict.txt > transfered-kaldi-format-text\n\n";
}

# begin subs
sub LoadDictAllowNakedWord {
    my ($inFile, $vocab) = @_;
    open(F, "$inFile") or die "## ERROR: cannot open file $inFile\n";
    while(<F>) {
	chomp;
      m:(^\S+)\s*(.*)$:g or next;
	my $word = $1;
	my $phoneStr = $2;
	$$vocab{$1} = $2;
    }
    close(F);
}
# end subs
my ($dictFile) = @ARGV;
my %vocab = ();
LoadDictAllowNakedWord($dictFile, \%vocab);
print STDERR "## stdin expected\n";
while(<STDIN>) {
    chomp;
    my @A = split(/\s+/);
    for(my $i = $from-1; $i < @A; $i ++) {
	if(exists $vocab{$A[$i]}) {
	    $A[$i] = $vocab{$A[$i]};
	} else {
	    if($print_warning) {
		print STDERR "## WARNING ($0): $A[$i] is an oov word ...\n";
	    }
	}
    }
    my $line = join(' ', @A);
    $line =~ s:\s+: :g;
    print "$line\n";
}
print STDERR "## stdin ended\n";
