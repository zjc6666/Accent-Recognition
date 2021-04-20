#!/usr/bin/perl
use strict;

# ////////////////////////////////////////////////////////////////////////////
 our(%romancode , %usercode , $CODEMAP, $LANGUAGE, $CHARNUMBER, $LANGLABEL, $VOWELNUMBER, $_AFFIX) ;   # a global hash table containing different character codes;
 $_AFFIX = "../chars/";

 $CODEMAP = $_AFFIX . "charmaps/Kazak.code"; #default code;
 $LANGUAGE = "Kazak"; $CHARNUMBER = 34; $VOWELNUMBER = 10; $LANGLABEL = "^"; #  labels.

 sub CodeInit {
    if(CodeMap($CODEMAP)) { print "The code-map-file: $CODEMAP is laoded successfuly.\n"; return 1}
    else { print "Failed to load the code-map-file $CODEMAP.\n"; return }   }
  
# ////////////////////////////////////////////////////////////////////////////

 # load th CODEMAP file into hash tables. 
sub CodeMap{
my $codeFile = $_[0];  
open CODEFILE, "<:utf8", $codeFile or return ; #  die $!;
while(my $codeline = <CODEFILE>)
{
     chomp $codeline; $codeline =~ s/\s+//g; 
     if($codeline)  
     {	      
	my ($acode, $codeID, $ucode)= split(/=/, $codeline, 3);
	# if(length($acode) eq 1 and $codeID  < 81 and $codeID >0 )
	if($acode  and $codeID )
	{  
            if(int($acode) eq $acode) { $acode = chr($acode);}  # can be used for double characters;
            if(not $romancode{$acode}){  $romancode{$acode} =  $codeID; } 
            else {print "error!!! there are duplicated codes for $acode = $codeID in the $codeFile file.\n"; close CODEFILE; return;} 
            # there are  many-to-one transfering ...
           for(split(/,/, $ucode))
           { if($_) {               
               my $wild = $_; # can be used for double code chars... 
               if(int($wild) eq $wild) { $wild = chr($wild); }
               if(not $usercode{$wild} )
	       {
                  $usercode{$wild}= $acode; # many-to-one unified.
	       } else { print "error!! there are ambiguous codes for character: $wild\n"; close CODEFILE; return ; }
             
           }}  # utf8 (or may be unicode, ?? really annoying) codes are loaded;
        }
    } 
} 
close CODEFILE;

my $asize = keys %romancode;   my $usize = keys %usercode;
if($asize < $CHARNUMBER ) { print "error!!! only $asize characters are not enough for $LANGUAGE.\n"; return;}
else {print "total $asize  target codes, mapped by $usize source codes, are loaded from file $codeFile\n"; return 1; }

} # sub CodeMap

# /////////////////////////////////////////////////////////
# IsWord function returns length of a word, return 0 if not pure word; 
 sub IsWord {
  my $ret = 0;  my ($word) = @_; if(not $word){ return;} 
  for(split(//, $word))
  {if($_){  my $cod = $romancode{$_};  if($cod >= 1 and $cod <=$CHARNUMBER or $_ eq $LANGLABEL) {$ret += 1; } else {return;}  }} 
  return $ret;
 } # sub IsWord;

# /////////////////////////////////////////////////////////
# IsVowel function returns number of vowels in a string;  
 sub IsVowel {
  my $ret = 0; my ($word) = @_; if(not $word){ return;} 
  for(split(//, $word))
  {if($_){  my $cod = $romancode{$_};  if(($cod > 1 and $cod <=$VOWELNUMBER) or ($_ eq "I") ) {$ret += 1; } else {return;}  }} 
  return $ret;
 } # sub IsWord;





1;

