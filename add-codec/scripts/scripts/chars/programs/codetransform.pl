#!/usr/bin/perl
use strict;

# ////////////////////////////////////////////////////////////////////////////
 my $_AFFIX = "./programs/";
 require $_AFFIX . "charmaps.pl";
 our(%romancode , %usercode , $CODEMAP, $LANGUAGE, $CHARNUMBER, $LANGLABEL, $VOWELNUMBER) ;   # a global hash table containing different character codes;
 $LANGLABEL = ""; #  labels.
 if(not CodeInit()) {print "failed while loading $CODEMAP, please check the extract location.\n"; usage();}
# //////////////////////////////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////////


 my $sfile = $ARGV[1]; my $dfile = $ARGV[2];   my $aFlag = $ARGV[0]; # "-alphabet";
 if($aFlag ne  "-alphabet")  { $sfile = $ARGV[0]; $dfile = $ARGV[1]; $aFlag = "";}
 else {$aFlag = 1;  }    # only alphabets not punctuation marks.

 if(not $sfile)   {  usage(); }
 else 
 {   if(not $dfile) { $dfile = $sfile ."_roman"; }     CodeFlip($sfile, $dfile);  }
  
# One to one code change between two sets of characters. 
# only many -> one code converting.....
sub CodeFlip {  
 # change all character codes from sfile to dfile according to code-map, but other codes remain untouched in the multi-lingual files;

my $sfile = $_[0]; my $dfile = $_[1];

open SOURCE, "<:utf8", $sfile or die $!;
open DEST,   ">:utf8", $dfile  or die $!;

my $linecount = 0;
while(my $sourceline = <SOURCE>)
{
     chomp $sourceline;  $sourceline = $sourceline . "!"; # add a last char, code never be able to get to this one.
     $linecount++;
     my $destline = "";  my $codeindex = 0;   my $token = "";
     my $linelen = length($sourceline) - 1; 
     while($linelen  > $codeindex)  
     {	
        my $char = substr($sourceline, $codeindex++, 1) ; 
        # //// for double chars............................
        if( ($linelen-$codeindex) > 2) 
        { 
            my $double = substr($sourceline, $codeindex-1, 2);
            if($usercode{$double}) { $char = $double; $codeindex++;  }
        }
        # //// for double chars............................
        my $target = $usercode{$char};  
        if($aFlag and not IsWord($target)) { $target = ""; $char = " "; } # when exporting only the alphabets,not puctuations.
        if ($target ) { $token = $token . $target;}  # the number 0 should not be missed.
        else
        { 
             # $char = " "; # only used to remove unknown characters or punctuations from characters;  
            if($token ne "")  { $destline = $destline . $LANGLABEL . $token . $char;  $token = "";  }
            else {   $destline = $destline . $char; }
        }
       
     }
  $destline =~ s/^\s+//;  $destline =~ s/\s+$// ; $destline =~ s/\s+/ /g;
   print DEST  "$destline\n";

}        
close SOURCE; close DEST;
print "code transfering are processed for $linecount lines.\n";
} # sub CodeFlip for a file;


sub usage {

 my $me = $0 ; # $me =~ s,^.*/,,;
 $me =~ s/^.*\///;

die <<HERE                                                            
Usage:
$me  [-alphabet]  sfile  [dfile]

Arguments:

sfile:    a text source file; character codes in this file will be
transformed according to the code-map file.
and the transformed text exported to the destination file "dfile".

dfile:    destination file; the characters in the "sfile" thansformed and 
saved to the "dfile". Optional, if not specified, then "sfilename_roman"
 is dfile name

-alphabet:   only the alphaber chars are transformed, others (puctuation marks, numbers,..) are ingored.

HERE
}


1;

