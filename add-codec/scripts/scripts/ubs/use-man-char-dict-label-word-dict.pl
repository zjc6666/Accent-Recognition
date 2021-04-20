#!/usr/bin/perl 

use strict;
use utf8;
use open qw(:std :utf8);

my ($char_lexicon_filename) = @ARGV;
open(CL, '<', $char_lexicon_filename);

my %char_dict=();
while(<CL>){
  chomp;
  m/(\S+)\s+(.+)/g;
  my ($char, $phoneseq)=($1, $2);
  if(not exists $char_dict{$char}){
    $char_dict{$char}=[$phoneseq];
  }
  else{
    push($char_dict{$char},$phoneseq);
  }
}

my @count=();
while(<STDIN>){
  chomp;
  m/(\S+)\s*(.*)/g;
  my ($wordseq,$phoneseq)=($1,$2);
  if($wordseq =~ m/[a-z]+/g){next;}
  my @chars=split("", $wordseq);
  my @lexseq=();

  print("$wordseq ");
  foreach my $c (@chars){
    print(" ");
    if(exists $char_dict{$c}){
      if((scalar @{$char_dict{$c}})==1){
        print("@{$char_dict{$c}}");
      }
      else{
        print("(@{$char_dict{$c}})");
      }
    }
    else{
      push(@count,$c);
    }
  }
  print("\n");
}

if(@count){print("@count\n");}

