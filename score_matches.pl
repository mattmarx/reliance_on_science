#!/share/pkg/perl/5.24.0/install/bin/perl

use strict;
#use warnings;

use Text::LevenshteinXS qw(distance);

# Print format is different depending on what this is set to (0,1,2,3)
# Command line arg "-debug" sets this to 3
my($debug)=0;

my($scoreprint)=1; # Print scores >= this value unless command line arg changes this
my($inputfile,%JournalAbbrev); # Globals
&process_command_line();
print "debugging\n" if ($debug);

# get English words in a lsit to filter
open(DICTIONARY,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/process_matches/probablyonlywords.txt")||die("can't find words file.\n");

my %EnglishWord;
while(<DICTIONARY>) {
   my($line)=$_;
   $line=lc($line);
   chomp($line);
   $EnglishWord{$line}=1;
}


# 100 most common words in English.  Skip these. Also includes numbers 0-10.
open(INFILE,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/process_matches/commonwords")||die("Can'f find commonwords file.\n");
my(%CommonWords);
while(<INFILE>) {
    my($word)=$_;
    $word=~s/\n//;
    $CommonWords{$word}=1;
}

# Very common surnames (1/10 of 1% of all names)
open(INFILE,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/process_matches/verycommonsurnames.csv")||die("Can't open verycommonsurnames.csv");
my(%VeryCommon);
while(<INFILE>) {
    my($line)=$_;
    $line=~s/\s+//;
    $line=lc($line);
    $VeryCommon{$line}=1;
}

# Somewhat common surnames (1/100 of 1% of all names)
open(INFILE,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/process_matches/somewhatcommonsurnames.csv")||die("Can't open somewhatcommonsurnames.csv");
my(%SomewhatCommon);
while(<INFILE>) {
    my($line)=$_;
    $line=~s/\s+//;
    $line=lc($line);
    $SomewhatCommon{$line}=1;
}

# Journal Abbreviations data.  Open file and then read in the data for use later.
#open(JOURNALS,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/inputs/journalabbrev/journalabbrevs.tsv")||die("Could not open journals abbreviations file in /projectnb/marxnsf1/dropbox/bigdata/nplmatch/journalabbrevs.tsv\n");
open(JOURNALS,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/inputs/journalabbrev/journalabbrevs-extended.tsv")||die("Could not open journals abbreviations file in /projectnb/marxnsf1/dropbox/bigdata/nplmatch/journalabbrevs-extended.tsv\n");
&ReadJournals();


if (!$debug) {
    print "ReferenceSource\tConfidence\tVolIssPageScore\tTitleScore\tLevMinDist\tTitlePct\tBestTitlePct3+\tPerfectUntil\tJournalScore\tCODE\tYEAR\tVOL\tISSUE\tFIRSTPAGE\tLASTPAGE\tFIRSTAUTHOR\tTITLE\tJOURNAL\tPatentID\tPatentLine\n";
}
if ($inputfile) {
    open(INFILE,"$inputfile")||die("Can't open input file $inputfile\n");
}

my($line,$wosid,$year,$vol,$issue,$firstpage,$lastpage,$firstauthor,$title,$journal,$patentid,$patentline);
my($vol_orig,$issue_orig,$firstpage_orig,$lastpage_orig,$title_orig,$patentline_orig,$patentline_numbers);
my($volisspage_score);
while(<INFILE>) {
    $line=$_;
    $line=~s/\n//;

    my(@rest);
    ($wosid,$year,$vol,$issue,$firstpage,$lastpage,$firstauthor,$title,$journal,$patentid,$patentline,@rest)=split(/\t/,$line);

    # Backups as we will modify some things
    $vol_orig=$vol;
    $issue_orig=$issue;
    $firstpage_orig=$firstpage;
    $lastpage_orig=$lastpage;
    $title_orig=$title;
    $patentline_orig=$patentline;
    $patentline_numbers=$patentline;
    if ($patentline_numbers) { $patentline_numbers=~s/doi[:=\s]+[\d\.\/]+/doixxxxxxxxx/; }
    if ($patentline_numbers) { $patentline_numbers=~s/isbn[\s\:\#]+[\d\.\-]+/isbnxxxxxxxxx/; }
    if ($patentline_numbers) { $patentline_numbers=~s/http:[^\s,\)]+/httpxxxxxxxxx/; }

    if ($vol) { $vol=~s/[^0-9-]/ /g; }
    if (($vol)&&($vol==0)) { $vol = "" } ##MMADD many MAG volumes are 0; ignore this
    if ($issue) { $issue=~s/[^0-9-]/ /g; }
    if ($firstpage) { $firstpage=~s/[^0-9-]/ /g; }
    if ($lastpage) { $lastpage=~s/[^0-9-]/ /g; }
#    $lastpageplusone = $lastpage+1; #often off by one...hmm this caused too many false positives
#    $lastpageminusone = $lastpage-1; #but you'll have to write two copies of every rule to include this :-(`

    if ($title) { $title=~s/[^a-zA-Z0-9]/ /g; }
    if ($title) { $title=~s/cheminform abstract //; } #MMADD lots of this, driving down the title match socre 
    if ($journal) { $journal=~s/[^a-zA-Z0-9_ \t&.:-]//g; }
    if ($journal) { $journal=~s/\s+$//g; }
    if ($patentline) { 
     print "PRELINE: $patentline\n" if $debug;
     $patentline=~s/\.sub\.//g; 
     $patentline=~s/\/sub (\d+)\//$1/g; 
     $patentline=~s/\.alpha\./ alpha /g;
     $patentline=~s/\.beta\./ beta /g;
     $patentline=~s/\.gamma\./ gamma /g;
     $patentline=~s/\.lambda\./ lambda /g;
     $patentline=~s/\.delta\./ delta /g;
     $patentline=~s/[^a-zA-Z0-9]/ /g; 
     print "PPOSTLINE: $patentline\n" if $debug;
    }
    # Include hyphens to support volumes of the form like "2-3"
    if ($patentline_numbers) { $patentline_numbers=~s/[^0-9-]/ /g; }
    print "patent line numbers = $patentline_numbers\n" if ($debug);


    my(@title_words)=split(/\s+/,$title);
    my(@patent_elements)=split(/\s+/,$patentline);


    # Start scoring sequence.  We are assuming YEAR and FIRSTAUTHOR have already matched so ignoring those.
    # However, recent algorithm changes allow YEAR to sometimes not be present of be off by 1 and 
    # FIRSTAUTHOR can have a typo (Levenshtein Distance 1) in it if in the early words.
    $volisspage_score=0;

    # vol issue first page, high #s
    if ($vol&&$issue&&$firstpage&&
	($patentline_numbers=~/\D+$vol\s{1,8}$issue\s{1,8}$firstpage\D+/)&&!
	($year==$vol)&&
	(!($vol<100&&$issue<100&&$firstpage<100))) { 
	$volisspage_score=16; 
    } 
    # vol issue first page, low numbers
    elsif ($vol&&$issue&&$firstpage&&
	   ($patentline_numbers=~/\D+$vol\s{1,8}$issue\s{1,8}$firstpage\D+/)&&
	   (!($year==$vol))&&
	   (!($vol<10&&$issue<10&&$firstpage<10))) { 
	$volisspage_score=14; 
    } 
    # vol issue first page with an extra number between vol and issue, high #s
    elsif ($vol&&$issue&&$firstpage&&
	   ($patentline_numbers=~/\D+$vol\s{1,8}\d+\s{1,8}$issue\s{1,8}$firstpage\D+/)&&
	   (!($year==$vol))&&
	   (!($vol<100&&$issue<100&&$firstpage<100))) { 
	$volisspage_score=15; 
    } #
    # vol issue first page with an extra number between vol and issue, low #s
    elsif ($vol&&$issue&&$firstpage&&
	   ($patentline_numbers=~/\D+$vol\s{1,8}\d+\s{1,8}$issue\s{1,8}$firstpage\D+/)&&
	   (!($year==$vol))&&
	   (!($vol<10&&$issue<10&&$firstpage<10))) { 
	$volisspage_score=14; 
    } 
    # vol issue first page with an extra number between issue and first page, big #s
    elsif ($vol&&$issue&&$firstpage&&
	   ($patentline_numbers=~/\D+$vol\s{1,8}$issue\s{1,8}\d+\s{1,8}$firstpage\D+/)&&
	   (!($year==$vol))&&
	   (!($vol<100&&$issue<100&&$firstpage<100))) { 
	$volisspage_score=15; 
    } 
    # vol issue first page with an extra number between issue and first page, small #s
    elsif ($vol&&$issue&&$firstpage&&
	   ($patentline_numbers=~/\D+$vol\s{1,8}$issue\s{1,8}\d+\s{1,8}$firstpage\D+/)&&
	   (!($year==$vol))&&
	   (!($vol<10&&$issue<10&&$firstpage<10))) { 
	$volisspage_score=14; 
    } 
    # volume followed by the two pages without other numbers in between should also be very good
    elsif ($vol&&$firstpage&&$lastpage&&
	   ($patentline_numbers=~/\D+$vol\D{1,8}$firstpage ?- ?$lastpage\D+/)&&
	   (!($year==$vol))&&
	   (!($vol<10&&$firstpage<10&&$lastpage<10))) { 
	$volisspage_score=15; 
    } 
    # also allow for year to come between vol and pages
    elsif ($vol&&$firstpage&&$lastpage&&
	   ($patentline_numbers=~/\D+$vol\D{1,8}\d{4}\D{1,8}$firstpage ?- ?$lastpage\D+/)&&
	   (!($year==$vol))&&
	   (!($vol<10&&$firstpage<10&&$lastpage<10))) { 
	$volisspage_score=15; 
    } 
    # also the case where lastpage is truncated
    elsif ($vol&&$firstpage&&$lastpage&&
	   ($patentline_numbers=~/\D+$vol\D{1,8}$firstpage ?- ?\d*(\d)\D+/)&&
	   ($lastpage=~/$1$/)&&
	   (!($year==$vol))&&
	   (!($vol<10&&$firstpage<10&&$lastpage<10))) { 
	$volisspage_score=15; 
    }
    #volume can come after page page, uncommon
    elsif ($vol&&$firstpage&&$lastpage&&
	   ($patentline_numbers=~/\D+$firstpage ?- ?$lastpage\D{1,8}$vol\D+/)&&
	   (!($year==$vol))&&
	   (!($vol<10&&$firstpage<10&&$lastpage<10))) { 
	$volisspage_score=15; 
    } 
    elsif ($vol&&$firstpage&&$lastpage&&
	   ($patentline_numbers=~/\D+$firstpage ?- ?\d*(\d)\D{1,8}$vol\D+/)&&
	   ($lastpage=~/$1$/)&&
	   (length($firstpage)>length($lastpage))&&
	   (!($year==$vol))&&
	   (!($vol<10&&$firstpage<10&&$lastpage<10))) { 
	$volisspage_score=15; 
    }
    # long volume and long first page alone can be conclusive
    elsif ($vol&&$firstpage&&
	   ($patentline_numbers=~/\D$vol\D{1,8}$firstpage\D/)&&
	   (!($year==$vol))&&($vol>999)&&($firstpage>999)) { 
	$volisspage_score=12; 
    } 
    elsif ($vol&&$firstpage&&
	   ($patentline_numbers=~/\D$vol\D{1,8}$firstpage\D/)&&
	   (!($year==$vol))&&$vol>99&&$firstpage>99) { 
	$volisspage_score=10; 
    }
    else {
        print "no VIP sequences matched.\n" if ($debug);
	if ($vol && !($vol==$year)) { #MMADD if the volume is the same as the year then this will always match and is meaningless
	    # If line explicitly says "Vol. ##" use that as the volume and give bonus points for a match but substract
	    # heavy points for no match in this case.
	    if ($patentline_orig=~/\W+vol\.* (\d+)\D+/i) {
		print "volume match\n" if ($debug);
		my($patent_vol)=$1;
		if ($vol==$patent_vol) { 
		    $volisspage_score+=2; 
		    if ($vol>999) { $volisspage_score+=3;} #MMADD more credit for matching longer volumes; now we only penalize single digit
		    elsif ($vol>99) {$volisspage_score+=2;}
		    # Downgrade single digit numbers as they are much more
		    # likely to happen by coincidence.
		    if ($vol<10) { $volisspage_score-=1; }
		}
		else { $volisspage_score-=4; }
	    }
	    elsif ($patentline_numbers=~/\D+$vol\D+/) { 
		#print "Hello\n";
		$volisspage_score+=2;
		if ($vol==1) {            ##MMADD -3 for vol=1 
		    $volisspage_score-=3;
	        }
	    }
	}

	# Only score anything for issue if Volume has gotten some kind of match.
	if (($volisspage_score>0)&&$issue&&($patentline_numbers=~/\D+$issue\D+/)) { 
	    $volisspage_score+=2; 
	    # Downgrade single digit numbers as they are much more
	    # likely to happen by coincidence.
	    if ($issue<10) { $volisspage_score-=1; }
	    if ($issue==1) { $volisspage_score-=1; }
	}
	# Remove points given above if Vol=1 and no Issue match.
	elsif (($volisspage_score>0)&&($vol==1)) { 
	    $volisspage_score-=3;
	}

	# Extra reward for being in the form "#-#"
	if (($firstpage)&&($lastpage)) {
	    # If line explicitly says "[p]p. ##-##" use that as the first and last page and give bonus points for a match but substract
	    # heavy points for no match in this case.
	    if ($patentline_orig=~/\W+p{1,2}\.* (\d+)-(\d+)\D+/i) {
print "pp.\n" if ($debug);
		my($patent_firstpage)=$1;
		my($patent_lastpage)=$2;
		if (($firstpage==$patent_firstpage)&&
		    ($lastpage=~/$patent_lastpage$/)&&
		    (length($firstpage)==length($lastpage))) { 
		    $volisspage_score+=5; #MM 8->6 
print "vip=$volisspage_score\n" if ($debug);
		    if ($firstpage>=1000) { $volisspage_score+=5; } #MMADD if it is four-digit numbers, give a lot of credit
		    elsif ($firstpage>=100) { $volisspage_score+=4; }
		    elsif ($firstpage>=10) { $volisspage_score+=2; }
		    if ($firstpage==1) {
			if ($patentline_numbers=~/\D+$vol\D+/) {
			    $volisspage_score-=1;
			}
			else {
			    $volisspage_score-=3; 
			}
		    }
		}
		# One matches.  Small positive as could be a typo in other one.
		elsif (($firstpage==$patent_firstpage)||
		       ($lastpage==$patent_lastpage)) { 
		    $volisspage_score+=1; # was +=2 
print "pp. partial match\n" if ($debug);
		}
		# Neither matches
		else { 
                    print "penalizing for not matching page #s\n" if ($debug);
		    $volisspage_score-=12;  # was -=8
		}
	    }
	    # If line explicitly says "[p]p. ##" use that as the first page and give bonus points for a match but substract
	    # heavy points for no match in this case.
	    elsif ($patentline_orig=~/\W+p{1,2}\.* (\d+)\D+/i) {
		my($patent_firstpage)=$1;
		if ($firstpage==$patent_firstpage) { $volisspage_score+=4; }
		else { $volisspage_score-=6; }
	    }
	    # Otherwise give large bonus points for the first and last pages matching in the form "#-#"
	    elsif ($patentline_numbers=~/\D+$firstpage-$lastpage\D+/) { 
		$volisspage_score+=5; 
		if ($firstpage>=1000) { $volisspage_score+=5; }
		elsif ($firstpage>=100) { $volisspage_score+=3; }
		elsif ($firstpage>=10) { $volisspage_score+=2; }
		if ($firstpage==1) {
		    if ($patentline_numbers=~/\D+$vol\D+/) {
			$volisspage_score-=1;
		    }
		    else {
			$volisspage_score-=3; 
		    }
		}
	    }
	    # Handles the case where the patent line says something like 4427-37 when it really means 4437 as the last page
	    elsif (($patentline_numbers=~/\D+$firstpage-(\d+)\D+/)&& 
		   ($lastpage=~/$1$/)&&
		   (length($firstpage)>length($lastpage))) { 
		$volisspage_score+=4; 
		if ($firstpage>=1000) { $volisspage_score+=5; }
		elsif ($firstpage>=100) { $volisspage_score+=3; }
		elsif ($firstpage>=10) { $volisspage_score+=2; }
	    }
	    else {
		if ($patentline_numbers=~/\D+$firstpage\D+/) { 
		    $volisspage_score+=2;
		    # Downgrade single digit numbers as they are much more
		    # likely to happen by coincidence.
		    if ($firstpage<10) { $volisspage_score-=1; }
		    # downgrade '1' as it is MUCH more likely to happen by coincidence #MMADD
		    if ($firstpage==1) { $volisspage_score-=2; } #MMADD
		}
		if (($firstpage!=$lastpage)&&($patentline_numbers=~/\D+$lastpage\D+/)) { 
		    $volisspage_score+=2; 
		    # Downgrade single digit numbers as they are much more
		    # likely to happen by coincidence.
		    if ($lastpage<10) { $volisspage_score-=1; }
		    # downgrade '1' as it is MUCH more likely to happen by coincidence #MMADD
		    if ($firstpage==1) { $volisspage_score-=2; } #MMADD
		}
	    }
	}
	elsif ($firstpage) {
	    # If line explicitly says "[p]p. ##" use that as the first page and give bonus points for a match but substract
	    # heavy points for no match in this case.
	    if ($patentline_orig=~/\W+p{1,2}\.* (\d+)\D+/i) {
		my($patent_firstpage)=$1;
		if ($firstpage==$patent_firstpage) { 
		    $volisspage_score+=4; 
		}
		else { 
		    print "pp. ##=## did not match; penalizing\n" if ($debug);
		    $volisspage_score-=10; ##MM changed -6 to -10
		}
	    }
	    # Otherwise give bonus points for the page matching in the form "#-"
	    elsif ($patentline_numbers=~/\D+$firstpage-\d+/) { 
		$volisspage_score+=4;
		if ($firstpage==1) { #MMADD
		    $volisspage_score-=2;
		} 
	    }
	    elsif ($patentline_numbers=~/\D+$firstpage-\D+/) { 
		$volisspage_score+=2;  
		if ($firstpage==1) { ##MADD
		    $volisspage_score-=2;
		}
	    }
	}
	# If NPL has a line of the form ###(#..)-##(#..) and the first number is not equal to our
	# $firstpage # and this case wasn't handled above, heavily penalize it.
	#if (($firstpage)&&($lastpage)&&($patentline_orig=~/(\d\d\d+)-\d\d+/)&&($firstpage!=$1)) { #MMADD such a problem I want to double-penalize it
	#    $volisspage_score-=15;
	#}
	# MMADD this should allow testing for missing ##-## but making sure it's not dates of conferences by requirin first two-digit number to be 32 or more. and 
	if (($firstpage)&&($lastpage)&&($patentline_orig=~/(\d\d+)-(\d+)/)&&($firstpage!=$1)&&(($1>31)||($2>31))) { #MMADD such a problem I want to double-penalize it
	    $volisspage_score-=15;
print "found ##-## in NPL, checking....\n" if ($debug);
	}
	# MMADD this should allow testing for missing ##-## beven if second number is shortened ; note, cannot check for second # >31 because we need to capture just the final digit
	if (($firstpage)&&($lastpage)&&($patentline_orig=~/(\d\d+)-\d+(\d)/)&&($firstpage!=$1)&&($1>31)&&($lastpage=~/$2$/)) { #MMADD such a problem I want to double-penalize it
print "found ##-## in NPL, checking-2....\n" if ($debug);
	    $volisspage_score-=15;
	}	# MMADD thidon't apply the date constraint but it has a volume right before so it doesn't look like dates
	if (($firstpage)&&($lastpage)&&($patentline_orig=~/\d+\s(\d\d+)-(\d\d+)/)&&($firstpage!=$1)) { #MMADD such a problem I want to double-penalize it
	    $volisspage_score-=15;
print "found ##-## in NPL, checking-3....\n" if ($debug);
	}
	# Penalize things where some or all of the vol, issue, first page, and last page are the same number as one match then gives two or three for free.  Only do this if there were some matches above.
	if ($volisspage_score>0) {
	    if ($vol==$issue&&$vol&&$issue) {
		$volisspage_score-=2;
print "vol=issue\n" if ($debug);
	    }
	    if ($issue==$firstpage&&$issue&&$firstpage) {
		$volisspage_score-=2;
	    }
	    if ($vol==$firstpage&&$vol&&$firstpage) {
		$volisspage_score-=2;
	    }
	    if ($vol==$lastpage&&$vol&&$lastpage) {
		$volisspage_score-=2;
	    }
	    if ($issue==$lastpage&&$issue&&$lastpage) {
		$volisspage_score-=2;
	    }
	}
    }    
    # even if had high VIP score, drop it if both issue and first page are 1 as this is a common mismatch
    if ($volisspage_score>10 && $issue==1 && $firstpage==1) {
	$volisspage_score = 7;
    }


    # Figure out title score
    my($title_score)=0;
    my($numwords);
    $numwords=@title_words;
    my($most_common_difference)="";
    my(%numdifferences);
    undef %numdifferences;
    my(@index,@difference,@common);
    for(my($wordct)=0;$wordct<$numwords;$wordct++) {
	my($word)=$title_words[$wordct];
	$index[$wordct]=&mymemberindex($word,@patent_elements);
	if ($CommonWords{$word}) {
	    $common[$wordct]=1;
	}
	else {
	    $common[$wordct]=0;
	}
	if ($index[$wordct]) {
	    $difference[$wordct]=$index[$wordct]-$wordct;
	    $numdifferences{$difference[$wordct]}++;
	}
#	print "Word: $word Common: $common[$wordct] Diff: $difference[$wordct]\n";
    }

    my($mostcommondifference)=0;
    my($occurrences)=0;
    
    my($difference);
    foreach $difference (keys %numdifferences) {
#	print "Diff: $difference Number: $numdifferences{$difference}\n";
	if ($numdifferences{$difference}>$occurrences) {
	    $mostcommondifference=$difference;
	    $occurrences=$numdifferences{$difference};
	}
    }

    my($maxtitle_score)=$numwords*4;
    my($perfectuntil)=0;
    my($bestpercent)=0;
    for(my($wordct)=0;$wordct<$numwords;$wordct++) {
	my($word)=$title_words[$wordct];

	if ($index[$wordct]) {
	    # Give 4 points for uncommon matching word in matching position (or within 1 pos of)
	    # Give 2 points for common word in matching position (or withing 1 pos of)
	    # Give 2 points for uncommon word found anywhere
	    # Give 0 points for common word found in non-matching position
	    if (($common[$wordct]==0)&&
		($difference[$wordct]<=$mostcommondifference+1)&&
		($difference[$wordct]>=$mostcommondifference-1)) { 
		$title_score+=4; 
	    }
	    elsif (($difference[$wordct]<=$mostcommondifference+1)&&
		   ($difference[$wordct]>=$mostcommondifference-1)) { 
		$title_score+=2; 
	    }
	    elsif ($common[$wordct]==0) { $title_score+=2; }
	}
	else {
	    # Give 3 points to Levenshtein Distance 1 uncommon words (the word we are comparing to is the word in the most common offset position)
	    if (($common[$wordct]==0)&&($patent_elements[$mostcommondifference+$wordct-1])) {
		my($distance)=distance($word,$patent_elements[$mostcommondifference+$wordct-1]);
		if ($distance==1) { 
		    $title_score+=3; 
		}
#		print "Distance from $word to $patent_elements[$mostcommondifference+$wordct-1] is $distance - MCD: $mostcommondifference Wordct: $wordct\n";
	    }
	}
	if (($title_score/(($wordct+1)*4))==1) { $perfectuntil=$wordct+1; }
	# Starting with word 4 of the title, compute the best percentage of maximum possible score achieved so far. Keep track of the highest value of this.
	if (($wordct>=3)&&(($title_score/(($wordct+1)*4))>$bestpercent)) { 
	    $bestpercent=$title_score/(($wordct+1)*4); 
	}
    }


    # Figure out title score based on Levenshtein distance to quoted strings
    my $temp=$patentline_orig;
    $temp=~s/\"\"/\"/g;
    $temp=~s/\"\"/\"/g;
    $temp=~s/\"\"/\"/g;
    my $quotecount = $temp =~ tr/\"//;
    my($levmindist)=50;
    if ($quotecount>=2) {
	my(@parts)="";
	@parts=split(/\"/,$temp);
	my($numparts);
	$numparts=@parts;

	my($i);
	my($levdist);
	my($title_orig_nospaces)=$title_orig;
	$title_orig_nospaces=~s/\s+//g;
	my($titlelength)=length($title_orig_nospaces);
	for($i=1;$i<$numparts;$i+=1) {
	    my($maybetitle)=$parts[$i];
	    $maybetitle=~s/[^a-zA-z0-9]//g;
	    my($maybetitlelength)=length($maybetitle);
	    # Skip if title lengths differ significantly
	    if (abs($titlelength-$maybetitlelength)>10) { next; }
	    $levdist=distance($title_orig_nospaces,$maybetitle);
	    print "Levenshtein Distance: $levdist - Compared $title_orig_nospaces XXXTOXXX $maybetitle\n" if ($debug);
	    if ($levdist<$levmindist) { $levmindist=$levdist; }
	}	    	
    }

    my($percentage,$unadj_percentage);
    if ($maxtitle_score) { 
	$percentage=$title_score/$maxtitle_score*100;

	# Give a bonus for long titles and penalty for short titles.  Multiplicative 
	# bonus equals [# of words in title/7] with a max of 1.5
	my($multiplier)=1.0;
	if ($numwords>=7) {
	    $multiplier=$numwords/7.0;
	}
	elsif ($numwords==7) {
	    $multiplier=1.05;
	}
	elsif (($numwords==4)&&($levmindist>2)) {
	    $multiplier=0.95;
	}
	elsif (($numwords==3)&&($levmindist>2)) {
	    $multiplier=.9;
	}
	elsif (($numwords==2)&&($levmindist>2)) {
	    $multiplier=.75;
	}
	elsif (($numwords==1)&&($levmindist>0)) {
	    $multiplier=.5;
	}
	if ($multiplier>1.5) { $multiplier=1.5; } #MADD move max multipler from 3 to 1.5
	$unadj_percentage=$percentage;
	$percentage=$percentage*$multiplier;
    }
    else {
	$percentage=0.0;
    }
    $bestpercent*=100;


    #MADD a bunch of MAG titles are wrong with symposium, conference, proceedings, ieee 
    if ($title=~/proceedings/ || $title=~/conference/ || $title=~/symposium/ || $title=~/ieee/) {
	$percentage -= 20;
    }
    

    my($print)=0;
    my($confidence)=0;
    # Perfect or nearly perfect VolIssPage match AND excellent title score
    # Set confidence high enough that even with penalties such as for common
    # author name will stay in the near-certain match category.
    if (($volisspage_score>=9)&&(($percentage>80)||($bestpercent>=85)||($levmindist<2))) {
	$confidence=12;
    }
    # Incredibly good title score for long title and reasonable VIP score
    elsif ((($percentage>100)||($levmindist<2))&&
	   ($volisspage_score>=4)) {
	$confidence=11;
    }
    # Incredibly good title score for long title and non-negative VIP score
    elsif ((($percentage>100)||($levmindist<2))&&
	   ($volisspage_score>=0)) {
	$confidence=10;
    }
    # Excellent title score and non-negative VIP score
    elsif ((($percentage>85)||($bestpercent>=90)||($levmindist<4))&&
	   ($volisspage_score>=0)) {
	$confidence=9;
    }
    # Extremely high VIP page score (mostly sequential vol-iss-page matches)
    elsif ($volisspage_score>=14) {
	$confidence=9;
    }
    # Really good title score and non-negative VIP score
    elsif ((($percentage>75)||($bestpercent>=85)||($levmindist<5))&&
	   ($volisspage_score>=0)) {
	$confidence=8;
    }
    # Extremely high VIP page score
    elsif ($volisspage_score>=10) {
	$confidence=7;
    }
    # Great score on full title even though negative VIP
    elsif (($percentage>100)||($levmindist<2)) {
        $confidence=7;
    } 
    # Pretty good score in both VIP and Title
    elsif ((($volisspage_score>=4)&&(($percentage>40)||($bestpercent>50)||($levmindist<6)))|| 
	   (($volisspage_score>=6)&&(($percentage>35)||($bestpercent>40)||($levmindist<7)))) { 
	$confidence=6;
    }
    # Great score on full title even though negative VIP
    elsif (($percentage>75)||($levmindist<5)) {
        $confidence=5;
    } 
    # Ok score in both VIP and Title or quite good VIP score
    elsif ((($volisspage_score>=2)&&(($percentage>40)||($bestpercent>50)||($levmindist<6)))||
	   ($volisspage_score>=6)){ 
	$confidence=4;
    }
    # Ok VIP or title match
    elsif ((($percentage>40)||($bestpercent>50)||($levmindist<6))||
	   ($volisspage_score>=4)) { 
	$confidence=3;
    }
    # boost anything with percentage>100, these are never wrong
    #if (($percentage>100)||(($levmindist==0)&&($numwords>=3))) {
    if (($percentage>75)&&($levmindist==0)&&($numwords>=3)) {
	$confidence+=4;
    }

    # Increase confidence if journal match found
    my($journal_score)=0;
    my($journal_abbrev)="";

    if (length($journal)>=3) {
	if ($patentline_orig=~/\W+$journal\W+/) {
	    if (!($journal=~/\s+/)) {
		$journal_score=1; 
	    }
	    elsif (length($journal)>5) {
		$journal_score=2; 
	    }
	    else {
		$journal_score=1; 
	    }
	}
	elsif ($JournalAbbrev{$journal}) {
	    $journal_score=&MatchJournal($journal,$patentline_orig);
	}
	$confidence+=$journal_score;
    }


    # SURNAMES SECTION START
    # Penalize very common and very short last names
    my($surname)=$firstauthor;
    $surname=~s/,.*$//;
    my($givename) = $firstauthor;
    $givename=~s/.*,\s?//;
    $givename=~s/\s.*//;
    my($firstinitial)=$1 if $givename=~/^(\w)/;
    print "author = >$firstauthor<\n" if ($debug);
    print "surname = >$surname<\n" if ($debug);
    print "given name = >$givename<\n" if ($debug);
    print "first initial = <$firstinitial>\n" if ($debug);
    # Penalize for Very Common or Very Short or English Word
    if ($VeryCommon{$surname}||(length($surname)<=2)||$EnglishWord{$surname}) { ##MM moved the <2 test here instead 
	print "Very Common Name, Very Short Name, or English Word <$surname>-> Conf -2<\n" if ($debug);
	$confidence-=2; 
    }
    elsif ($SomewhatCommon{$surname}) { 
	print "Somewhat Common Name <$surname>-> Conf -1<\n" if ($debug);
	$confidence-=1; 
    }
    # penalize if missing name exact match 
    if (!(($patentline=~/^$surname\W+/)||($patentline=~/\W+$surname\W+/))) {
	print "can't find exact author name! $surname not in the line penalizing -1 \n" if ($debug);
	$confidence-=1;
    } 

    # scratching bad names. could instead preprocess the names to clean up the data. not sure which is bette 
    if ($CommonWords{$surname}) {
	print "surname <$surname> is a common word - probably bad data -> Conf -6\n" if ($debug);
	$confidence=-6;
    }

    # names that are month abbreviations are especially problematic, decrement them again
    if (($surname eq "jan")||($surname eq "feb")||($surname eq "mar")||($surname eq "apr")||($surname eq "may")||($surname eq "jun")||($surname eq "jul")||($surname eq "aug")||($surname eq "sep")||($surname eq "oct")||($surname eq "nov")||($surname eq "dec")) {
	print "Surname is month <$surname>-> Conf -3\n" if ($debug);
	$confidence-=2;
    }
    # clearly not author names
    if (($surname eq "sales")||($surname eq "gate")||($surname eq "czech")||($surname=~/^article/)||($surname eq "rule")||($surname eq "app")||($surname eq "francisco")||($surname eq "berlin")||($surname=~/consultant/||$surname eq "daily")||($surname eq "apple")||($surname eq "daily")||($surname eq "canada")||($surname eq "camp")||($surname eq "chem")||($surname eq "dept")||($surname eq "screening")||($surname=~/^abstract/)||($surname eq "pages")||($surname eq "transaction")||($surname eq "activity")||($surname eq "introduction")||($surname eq "division")||($surname eq "san")||($surname eq "index")||($surname eq "list")||($surname eq "ab")||($surname eq "san")||($surname eq "pages")||($surname eq "ad")||($surname eq "ocean")||($surname eq "other")||($surname eq "we")||($surname eq "to")||($surname eq "pi")||($surname eq "ok")||($surname eq "my")||($surname eq "it")||($surname eq "is")||($surname eq "if")||($surname eq "en")||($surname eq "em")||($surname eq "al")||($surname eq "et")||($surname eq "do")||($surname eq "be")||($surname eq "at")||($surname eq "and")||($surname eq "by")||($surname=~/ieee/)||($surname=~/general/)||($surname=~/paper/)||($surname=~/english/)||($surname eq "usa")||($surname=~/nasa/)||($surname eq "eng")||($surname eq "no")||($surname=~/magazine/)||($surname=~/journal/)||($surname eq "new")||($surname eq "head")||($surname eq "risk")||($surname=~/galaxy/)||($surname eq "show")||($surname eq "org")||($surname eq "array")) {
        print "useless author <$surname>-> Conf -6\n" if ($debug);
	$confidence-=4; 
    }
    # probably not author names
    if (($surname eq "smart")||($surname eq "best")||($surname eq "back")||($surname eq "north")||($surname eq "rock")||($surname eq "high")||($surname eq "doi")||($surname eq "page")||($surname eq "blood")||($surname eq "baltimore")||($surname eq "san")||($surname eq "ran")||($surname eq "diamond")||($surname eq "america")||($surname eq "toyota")||($surname eq "brain")||($surname eq "power")||($surname eq "block")||($surname eq "can")) {
	$confidence-=2; 
    }

    if ($title=~/$surname/) {
	print "author is same as title, data error\n" if ($debug);
	$confidence-=5;
    }
    
    # experimental: slight penalty if author is not early in the NPL ( will also penalize fuzzy matches, note)
    my($probcontains1stauth,$authornotearly);
    my($nopenalizefinit)=0;
    my($nplfirstinitial);
    if ($patentline_orig=~/^(\S+ \S+ \S+ \S+ \S+)/) {
#    if ($patentline_orig=~/^(.{20})/) {
	$probcontains1stauth = $1;
	if (!($probcontains1stauth=~/$surname/)) {
	    print "dont' see author >$surname< in first five words>$probcontains1stauth<, penalizing\n" if ($debug);
	    $authornotearly = 1;
	    $confidence-=1;
	} else {
	    print "found <$surname> in first five words>$probcontains1stauth<\n" if ($debug);
	}
    }
    # experimental: check if first initial or first name does not match!
    if ($levmindist<5||$probcontains1stauth=~/^$surname,? et al/||$probcontains1stauth=~/^$surname\W+\d+/) {
	$nopenalizefinit=1;
    }
    if ($nopenalizefinit!=1&&$probcontains1stauth=~/$surname\W+(\w)\./) {
	print "have an early author name to check\n" if ($debug);
	$nplfirstinitial=$1;
        print "NPL first initial = >$nplfirstinitial< MAG first initial = >$firstinitial<\n" if ($debug);
        if ($nplfirstinitial ne $firstinitial) {
	    print "penalizing because first initials are different-> Conf -5\n" if ($debug);
	    $confidence -=5;
        }
    }
    if ($nopenalizefinit!=1&&$probcontains1stauth=~/$surname\W+(\S)\S* et al/) {
	print "have an early author name to check\n" if ($debug);
	$nplfirstinitial=$1;
        print "NPL first initial = >$nplfirstinitial< MAG first initial = >$firstinitial<\n" if ($debug);
        if ($nplfirstinitial ne $firstinitial) {
	    print "penalizing because first initials are different-> Conf -5\n" if ($debug);
	    $confidence -=5;
        }
    }
    if ($nopenalizefinit!=1&&$probcontains1stauth=~/^(\w)\. $surname\W+et al/) {
	print "have an early author name to check\n" if ($debug);
	$nplfirstinitial=$1;
        print "NPL first initial = >$nplfirstinitial< MAG first initial = >$firstinitial<\n" if ($debug);
        if ($nplfirstinitial ne $firstinitial) {
	    print "penalizing because first initials are different-> Conf -5\n" if ($debug);
	    $confidence -=5;
        }
    }
    if ($nopenalizefinit!=1&&$probcontains1stauth=~/^(\w)\w* $surname\W/) {
       print "have an early author name to check\n" if ($debug);
       $nplfirstinitial=$1;
       print "NPL first initial = >$nplfirstinitial< MAG first initial = >$firstinitial<\n" if ($debug);
       if ($nplfirstinitial ne $firstinitial) {
	   print "penalizing because first initials are different-> Conf -5\n" if ($debug);
	   $confidence -=5;
       }
    }
    if ($nopenalizefinit!=1&&$probcontains1stauth=~/^$surname (\w)\w+\W/) {
	print "have an early author name to check\n" if ($debug);
	$nplfirstinitial=$1;
        print "NPL first initial = >$nplfirstinitial< MAG first initial = >$firstinitial<\n" if ($debug);
        if ($nplfirstinitial ne $firstinitial) {
	    print "penalizing because first initials are different-> Conf -5\n" if ($debug);
	    $confidence -=5;
        }
    }
    if ($nopenalizefinit!=1&&$probcontains1stauth=~/and (\w)\w\.? $surname\W/) {
	print "have an early author name to check\n" if ($debug);
	$nplfirstinitial=$1;
        print "NPL first initial = >$nplfirstinitial< MAG first initial = >$firstinitial<\n" if ($debug);
        if ($nplfirstinitial ne $firstinitial) {
	    print "penalizing because first initials are different-> Conf -5\n" if ($debug);
	    $confidence -=5;
        }
    }
    if ($nopenalizefinit!=1&&$probcontains1stauth=~/and $surname, (\w)\w*\.?\W/) {
	print "have an early author name to check\n" if ($debug);
	$nplfirstinitial=$1;
        print "NPL first initial = >$nplfirstinitial< MAG first initial = >$firstinitial<\n" if ($debug);
        if ($nplfirstinitial ne $firstinitial) {
	    print "penalizing because first initials are different-> Conf -5\n" if ($debug);
	    $confidence -=5;
        }
    }
    if ($nopenalizefinit!=1&&$probcontains1stauth=~/$surname,? (\w)\w*[,\,]? and/) {
	print "have an early author name to check\n" if ($debug);
	$nplfirstinitial=$1;
        print "NPL first initial = >$nplfirstinitial< MAG first initial = >$firstinitial<\n" if ($debug);
        if ($nplfirstinitial ne $firstinitial) {
	    print "penalizing because first initials are different-> Conf -5\n" if ($debug);
	    $confidence -=5;
        }
    }
    if ($nopenalizefinit!=1&&$probcontains1stauth=~/(\w)\w*\.? $surname,? and/) {
	print "have an early author name to check\n" if ($debug);
	$nplfirstinitial=$1;
        print "NPL first initial = >$nplfirstinitial< MAG first initial = >$firstinitial<\n" if ($debug);
        if ($nplfirstinitial ne $firstinitial) {
	    print "penalizing because first initials are different-> Conf -5\n" if ($debug);
	    $confidence -=5;
        }
    }
    # SURNAMES SECTION END

    
    # Flexyear: decrement confidence if the year does not match
    my($yearplusone) = $year+1;
    my($yearminusone) = $year-1;
    if (!($patentline=~/\D$year\D/)&&!(/\D$yearplusone\D/)&&!(/D$yearminusone\D/)&&($levmindist>5)) {
        print "year is missing! penalizing -2\n" if ($debug);
	$confidence-=2;
    }
    elsif (!($patentline=~/\D$year\D/)&&($levmindist>5)) {
        print "year is off by one! penalizing -1\n" if ($debug);
	$confidence-=1;
    }

    # Large negative VIP and not perfect year match
    if (($volisspage_score<-10)&&(!($patentline=~/\D$year\D/))&&($levmindist>5)) {
        print "VIP below -10, Not perfect year-> Conf -2\n" if ($debug);
	$confidence-=2;
    }
    # Large negative VIP and same journal
    if (($volisspage_score<-10)&&($journal_score>1)&&($levmindist>5)) {
        print "VIP below -10, Journal 2+ -> Conf -2\n" if ($debug);
	$confidence-=2;

    # not same journal, but both NPL and MAG titles have "journal" so probably different journals
    } elsif (($volisspage_score<-10) && ($title=~/journal/&&$patentline=~/journal/)&&($levmindist>5)) {
        print "VIP below -10, Title includes 'journal' -> Conf -2\n" if ($debug);
        $confidence-=2;
    }

    # Scratch bad titles. could instead preprocess I suppose
    if ($title=~/^cold spring harbor laboratories$/||$title=~/request for comment/||$title=~/patent trial appeal/||$title=~/book review/||$title=~/united states district court/||$title=~/public hearing/||$title=~/letter from /||$title=~/workshop/||$title=~/letter to the editor/||$title=~/^proceedings of/||$title=~/comments on the/||$title=~/^reply to /||($title=~/\W$surname\W/)||($title=~/reply$/)||($title=~/respond$/)) {
        print "Non-paper MAG titles -> Conf -6\n" if ($debug);
	$confidence-=6;
    }
   

    # non-science NPLs. periodically should be moved to preprocessing#
    if ($patentline=~/english language derwent abstract/||$patentline=~/request for comment/||$patentline=~/united states district court/||$patentline=~/internet engineering task force/||$patentline=~/request for comment/||$patentline=~/amended complaint/||$patentline=~/expert opinion/||$patentline=~/ readme /||$patentline=~/declaration of /||$patentline=~/invalidity chart/||$patentline=~/motion to strike/||$patentline=~/request for comments/||$patentline=~/prior art chart/||$patentline=~/draft standard/||$patentline=~/webster.*dictionary/) {
    #if ($patentline=~/request for comment/||$patentline=~/working group/||$patentline=~/united states district court/||$patentline=~/internet engineering task force/||$patentline=~/request for comment/||$patentline=~/amended complaint/||$patentline=~/expert opinion/||$patentline=~/ readme /||$patentline=~/declaration of /||$patentline=~/invalidity chart/||$patentline=~/motion to strike/||$patentline=~/request for comments/||$patentline=~/prior art chart/||$patentline=~/draft standard/||$patentline=~/webster.*dictionary/) {
        print "Non-paper NPL titles -> Conf -6\n" if ($debug);
	$confidence-=6;
    }

 # this is hacky but if you have conf<3 and low lev, boost it
 if ($confidence<5 && $levmindist<5) {
   $confidence = 5;
 } 
 # also hacky but if you have high VIP and also a journal match, take it
 if ($volisspage_score>9 & $journal_score>0) {
   $confidence +=3;
 }
  
    my($refsource) = "unk";
    if ($patentline=~/by examiner/) {
	$refsource = "exm";
    }
    if ($patentline=~/by applicant/) {
	$refsource = "app";
    }
    if ($patentline=~/by other/) {
	$refsource = "oth";
    }

    # It is possible to have a confidence above 10 or below 0, reset to 10/0
#    if ($confidence>10) { $confidence=10; } # Removed on May 21, 2019 by Aaron.  Allow higher than 10 confidences.  Let sort later reduce them if we want to.
    if ($confidence<0) { $confidence=0; }

    my($string) = $refsource;

    if ($confidence>=$scoreprint) {
	$print=1;
    }
    else {
	$print=0;
    }

    if ($print) {
	if ($debug) {
	    print "$string";
	    printf("CONF: %d VIP_S: %d T_S: %3d LEVMINDIST: %3d PCT: %5.2f UNADJ_PCT: %5.2f BESTPCT: %5.2f PU: %2d TITLE_OFFSET: %d\n",$confidence, $volisspage_score,$title_score,$levmindist,$percentage,$unadj_percentage,$bestpercent,$perfectuntil,$mostcommondifference-1);
	    print "ID: $wosid AUTHOR: $firstauthor VOL: $vol ISS: $issue FPAGE: $firstpage LPAGE: $lastpage TITLE: $title_orig \tJOURNAL: $journal\n";
	    print "PATENT: $patentid PATENTLINE: $patentline_orig\n";
	    print "JOURNAL_SCORE: $journal_score ($journal_abbrev)\n";
	    if ($debug>=2) {
#		print "$vol\t$issue\t$firstpage\t$title_orig\t$journal\n";
#		print "$patentline_orig\n";
#		print "NUMS: $patentline_numbers\n";
#		print "$volisspage_score\n\n";
	    }
	    if ($debug>=3) {
		print "$line\n";
	    }
	    print "\n";
	}
	else {
	    printf("%s\t%d\t%d\t%3d\t%3d\t%5.2f\t%5.2f\t%2d\t%d\t%s\n",$string,$confidence,$volisspage_score,$title_score,$levmindist,$percentage,$bestpercent,$perfectuntil,$journal_score,$line);
	}
    }
}

sub process_command_line {
    my($i,$numargs);

    $numargs=@ARGV;

    my($retval)=1;
    if ($numargs==0) {
        &print_usage();
    }

    for($i=0;$i<$numargs;$i++) {
        if (($ARGV[$i])&&($ARGV[$i]=~/^-print/)) {
            if ($ARGV[($i+1)]=~/^\d+$/) {
                $scoreprint=$ARGV[($i+1)];
                $i++;
            }
            else {
		print "No score minimum given with -print argument\n";
                &print_usage();
            }
        }
        elsif (($ARGV[$i])&&($ARGV[$i]=~/^-debug/)) {
	    $scoreprint=0;
	    $debug=3;
        }
	else {
	    $inputfile=$ARGV[$i];
	}
    }
    if (($inputfile)&&(!(-e $inputfile))) {
	die("Usage: score_matches.pl filename_or_fullpath_of_file\n");
    }
}

sub print_usage {
    die "Usage: score_matches.pl [-printscore 1-10] filename\n";
}


# SEE IF AN ITEM IS PART OF AN ARRAY AND RETURN ITS INDEX NUMBER +1.  RETURN 0 IF NOT FOUND.
sub mymemberindex {
    my($matchitem,@myarray)=@_;
    my($numitems,$retval,$i);
    $retval=0;

    $numitems=@myarray;
    for($i=0;$i<$numitems;$i++) {
        if (($myarray[$i])&&("$matchitem" eq "$myarray[$i]")) {
            $retval=$i+1;
            $i=$numitems;
        }
    }

    $retval;
}


# Read in Journal Abbreviations information
sub ReadJournals {
    my($line,$journal,$abbrev,@rest);
    while(<JOURNALS>) {
	$line=$_;
	$line=~s/\n//;
	$line=~s/[^a-zA-Z0-9_ \t&.:-]//g; 
	($journal,$abbrev,@rest)=split(/\t/,$line);
	if ($JournalAbbrev{$journal}) {
	    $JournalAbbrev{$journal}.="\t$abbrev";
	}
	else {
	    $JournalAbbrev{$journal}="$abbrev";
	}
    }   
}


# Match up a journal that has abbreviations
sub MatchJournal {
    my($journal,$line)=@_;
    my(@parts,$numparts,$i);
    my($journal_abbrev,$retval);
   
    $retval=0;
 
    @parts=split(/\t/,$JournalAbbrev{$journal});
    $numparts=@parts;

    for($i=0;$i<$numparts;$i++) {
	if ($line=~/\W+$parts[$i]\W+/) {
	    $journal_abbrev=$parts[$i];
	    if (!($journal=~/\s+/)) {
		$retval=1; 
	    }
	    elsif (length($journal_abbrev)>5) {
		$retval=2; 
	    }
	    else {
		$retval=1; 
	    }
	}
    }

    return $retval;
}

