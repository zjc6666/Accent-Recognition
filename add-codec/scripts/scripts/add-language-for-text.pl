#!/usr/bin/perl

# 2020/11/16 Peng Yizhou
# Add language id for each transcription
# Only for OLR training set with trans

use strict;
use utf8;
use open qw(:std :utf8);

print STDERR "## LOG ($0): stdin expected ...\n";
while(<STDIN>) {
    chomp;
    m/(\S+)\s+(.*)/g or next;
    my ($utt, $text) = ($1, $2);
    my @languages = ("CHN", "CNT", "IDN", "JAP", "KZK", "KRN", "RUS", "TBT", "UYG", "VTN");
    my @utt_lang_id = ("zh-cn", "ct-cn", "id-id", "ja-jp", "Kazak", "ko-kr", "ru-ru", "Tibet", "Uyghu", "vi-vn");
    for (my $i=0; $i< scalar @utt_lang_id; $i++) {
	if ($utt =~ /$utt_lang_id[$i]/) {
	    my @words = split(" ", $text);
	    print("$utt ");
	    my $word = "";
	    for (my $j=0; $j<scalar @words; $j++) {
		if ($j == scalar @words - 1){
		    if($words[$j] =~ /</) {
			$word .= $words[$j];
			$word .= "\n";
		    }else {
			$word .= $words[$j];
			$word .= "_$languages[$i]\n";
		    } 
		}else{
		    if($words[$j] =~ /</) {
			$word .= $words[$j];
			$word .= " ";
		    }else{
			$word .= $words[$j];
			$word .= "_$languages[$i] ";
		    }
		}
		
	    }
	    print("$word"); 
	}
    }
}

print STDERR "## LOG ($0): stdin ended ...\n";
