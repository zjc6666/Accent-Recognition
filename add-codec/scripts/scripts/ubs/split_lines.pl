#!/usr/bin/perl -w
use strict;
use utf8; 
use open qw(:std :utf8);
use Getopt::Long;

my $prefix = "";
GetOptions("prefix=s", \$prefix) or die;
my $numArgs = scalar @ARGV;

my $usage =<<"EOF";

# split a text files in to N subsets, and each time we get the ith subset, assuming
# the total lines of the file is M.
Usage: cat text | $0 [options]  <the_ith_subset>  <total_subsets> <total_lines_of_the_input_file>  <dir>
[options]:
--prefix=             # prefix for the output file (default='$prefix')
Example: cat text | $0 1 50  10003  dir

EOF

if ($numArgs != 4) {
  die $usage;
}
my ($index, $N, $M, $dir) = @ARGV;

if($index -1 < 0 || $index - 1 >= $N || $N <= 0 || $N > $M) {
  die "\n## ERROR ($0): illegal index ($index), or total subsets ($N), or total lines of the file ($M)\n";
}
my $filename = sprintf("%04d", $index);
if ($prefix ne "") {
  $filename = $prefix . "_" . $filename;
}
my $output_filename = sprintf("%s/%s.txt", $dir, $filename);
my $lines_per_subset = int($M/$N);
my $start_index = ($index - 1) * $lines_per_subset;
my $end_index = $index * $lines_per_subset;
if($index == $N) {
  $end_index = $M;
}
open (OUTPUT, ">$output_filename") or die "## ERROR ($0): cannot open file '$output_filename' for the output\n";
my $line_count = 0;
print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
  chomp;
  if($line_count == 0) {
    print STDERR "## LOG ($0): stdin is seen ...\n";
  }
  if($line_count >= $start_index and $line_count < $end_index) {
    print OUTPUT "$_\n";
  }
  $line_count ++;
}
print STDERR "## LOG ($0): stdin is done \n";
close OUTPUT;
