#!/usr/local/bin/perl

require "/usr1/scv/aarondf/bin/Hunt/readdict.pl";

&ReadDictionary();

while (<>) {
#print "\n\n";
 #print;
 chop;
 $first = "";
 $firstisaword = 0;
 $second = "";
 $secondisaword = 0;
 #print "\n";
 print "$_\n";
 if (/([a-zA-Z]+)\s?\-\s?([a-z]+)/) {
  $first = $1;
  $second = $2;
  #print "$_\n";
 # print "checking >$1<->$2<\n";
  if ($Words{$first}) {
   # print "pre-hyphen $first is in the dictionary\n";
    $firstisaword = 1;
  }
  if ($Words{$second}) {
   # print "post-hyphen $second is in the dictionary\n";
	$secondisaword = 1;
  }
  if ($firstisaword==0 && $secondisaword==0) {
  # print "both of thoes aren'tt in the dictionary\n";
   $_ =~ s/([a-zA-Z]+)\s?\-\s?([a-z]+)/$1a$2/;
  } else {
  # print "one must  be in the dictionary, so don't replace\n";
  }
 print "$_\n";
 }
}

