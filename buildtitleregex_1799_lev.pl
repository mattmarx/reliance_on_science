#!/usr/local/bin/perl

$filesize=50000000;
$inputyear="1799";
$file=0;
if ($ARGV[0]=~/^wos$/i) {
    $inputfile="/projectnb/marxnsf1/dropbox/bigdata/nplmatch/inputs/wos/wosplpubinfo1955-2017_filteredISS.txt";
    $sourcefilecode="wos";
}
elsif ($ARGV[0]=~/^mag$/i) {
    $inputfile="/projectnb/marxnsf1/dropbox/bigdata/nplmatch/inputs/mag/mergedmagfornpl-fixednames.tsv";
    $sourcefilecode="mag";
}
else {
    $inputfile=$ARGV[0];
    $sourcefilecode="file";
    $file=1;
    
    if (!(-e $inputfile)) {
	die("Usage: buildtitleregex_1799.pl mag|wos|filename_or_fullpath_of_file\n");
    }
}

print "Using source directory/file: $inputfile  Sourcecode: $sourcefilecode\n\n";

$minlength=2;
$maxlength=100;

open(INFILE,$inputfile)||die("Can't open input file $inputfile");
# space separates patent & ref for the master NPL
# tab separates patent & ref for the yearly slices (and has the year at the end, which could create false positives

open(SKIPWORDSFILE,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splitword/skipwords")||die("Couldn't open skipwords file.\n");
while(<SKIPWORDSFILE>) {
    $word=$_;
    $word=~s/\s+//g;
    $SkipWord{$word}=1;
}
close(SKIPWORDSFILE);

open(SKIPTITLESFILE,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/badtitles.txt")||die("Couldn't open skiptitles file.\n");
while(<SKIPTITLESFILE>) {
    $title=$_;
    $title=~s/\n//;
    $SkipTitle{$title}=1;
}
close(SKIPTITLESFILE);

$outputdir="/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splittitle/year_regex_scripts_" . "$sourcefilecode". "/";

$inputdir="/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splitword/";

$date=`date`;
print "$date";

chdir("/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splittitle");

# Go through source (WOS|MAG|FILE) file
$linect=0;
while (<INFILE>) {
    $line=$_;

    $linect++;
    if (($linect % 100000)==0) {
	print "At line $linect\n";
    }

    chop($line);

    if (!$line) { next; }

    if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/) {
	$year = $1;
	$wosid = $2;
	$vol = $3;
	$issue = $4;
	$firstpage = $5;
	$lastpage = $6;
	$firstauthor = $7;
	$title=$8;
	$journal=$9;
    
	$year =~ s/\///;
	$wosid =~ s/\///;
	$vol =~ s/\///;
	$issue =~ s/\///;
	$firstpage =~ s/\///;
	$lastpage =~ s/\///;
	$title=~s/"//g;
	$journal=~s/"//g;

	# If a single ? in firstauthor name, treat it as a wildcard (.) character.  This is being 
	# done in a two phase process.  Remove additional ? and most other non-alphanumeric 
	# characters.
	$firstauthor=~s/\?/TEMPORARY/;
	$firstauthor=~s/[^a-zA-z0-9-_,' ]//g; # Remove problematic characters in author name
	$firstauthor=~s/\[//g; # Remove problematic characters in author name
	$firstauthor=~s/\]//g; # Remove problematic characters in author name
	$firstauthor=~s/TEMPORARY/./;

	$firstauthor_lastname=$firstauthor;
	$firstauthor_lastname =~ tr/[A-Z]/[a-z]/;
	$firstauthor_lastname =~ s/,.*//;
	$firstauthor_lastname =~ s/\///;

	# Title_print variable is used in the output line.  We get rid of all strange characters.
	$title_print=$title;
	$title_print=~s/[^a-zA-Z0-9-,'.(): ]//g;

	# Skip items with No author, "[anonymous]" author, before 1800, or after 2017
	if (($firstauthor_lastname eq "")||($firstauthor_lastname eq "[anonymous]")||($year<1799)||($year>2018)) { next; }

	# Mytitle is the version we use to split the title up in to words in the same way done in 'splitword'
	$mytitle=lc($title);
	# Skip titles in badtitles file
	if ($SkipTitle{$mytitle}) { next; }
	# Skip all titles less than 8 letters except GenBank
	if ((!("$mytitle" eq "genbank"))&&(length($mytitle)<8)) { next; }
	$mytitle=~tr/"-:;.,'/ /;

	# Find longest and second longest good word in title.
	@words="";
	@words=split(/\s+/,$mytitle);
	$prevword="";
	$longest=0;
	$secondlongest=0;
	$longestword="";
	$secondlongestword="";
	foreach $word (sort(@words)) {
	    $word=~s/[^a-zA-Z]*//g;

	    # Avoid duplicates
	    if ($word eq $prevword) { next; }

	    # Avoid very common words
	    if ($SkipWord{$word}) { next; }

	    if (length($word)>$longest) {
		if ($longestword) {
		    $secondlongest=$longest;
		    $secondlongestword=$longestword;
		}
		$longest=length($word);
		$longestword=$word;
	    }
	    elsif (length($word)>$secondlongest) {
		$secondlongest=length($word);
		$secondlongestword=$word;		
	    }

	    $prevword=$word;
	}

	if (($longestword)&&(length($longestword)>=2)) {
	    # Skip authors with no alphanumerics
	    if ($firstauthor=~/\w/) {
		if (length($firstauthor_lastname)>=4) {
		    $output="$wosid\t$year\t$vol\t$issue\t$firstpage\t$lastpage\t$firstauthor\t$title\t$journal\t";
		    $regex="\t&fullcompare(\$\_,\"$firstauthor_lastname\",\"$output\");\n";
		}
		else {
		    $regex= "\tif (/\[\^a\-zA\-Z0\-9\_\-\]$firstauthor_lastname\[\^a\-zA\-Z0\-9\_\-\]/) { print \"$wosid\t$year\t$vol\t$issue\t$firstpage\t$lastpage\t$firstauthor\t$title\t$journal\t\$_\"; }\n";
		}
		$Output{$longestword}.=$regex;
	    }
	}
	if (($secondlongestword)&&(length($secondlongestword)>=2)) {
	    # Skip authors with no alphanumerics
	    if ($firstauthor=~/\w/) {
		if (length($firstauthor_lastname)>=4) {
		    $output="$wosid\t$year\t$vol\t$issue\t$firstpage\t$lastpage\t$firstauthor\t$title\t$journal\t";
		    $regex="\t&fullcompare(\$\_,\"$firstauthor_lastname\",\"$output\");\n";
		}
		else {
		    $regex= "\tif (/\[\^a\-zA\-Z0\-9\_\-\]$firstauthor_lastname\[\^a\-zA\-Z0\-9\_\-\]/) { print \"$wosid\t$year\t$vol\t$issue\t$firstpage\t$lastpage\t$firstauthor\t$title\t$journal\t\$_\"; }\n";
		}
		$Output{$secondlongestword}.=$regex;
	    }
	}
    }
    else {
	print "No format match found for line $linect - $line\n";
    }
}

print "\n";


$sizect=$filesize;
$filect=0;
foreach $word (keys %Output) {
    if ($sizect>=$filesize) {
	$sizect=0;
	$filenum=$filect+1000;
	if ($filect!=0) { 
	    close(OUTFILE); 
	    `chmod 775 $outputfile`;
	}
	$filect++;
	$outputfile="$outputdir"."year"."$inputyear"."-"."$filenum".".pl";
	open(OUTFILE,">$outputfile");
	# Perl line and fullcompare function to support Levenshtein distance
	open(PERLFILE,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splittitle/template_perl")||die("Can't open Perl Template file template_perl\n");
	while(<PERLFILE>) {
	    print OUTFILE "$_";
	}
	close(PERLFILE);
    }
    $firstletter=substr($word,0,1);
    $secondletter=substr($word,1,1);
    $wordfilepath="$inputdir"."$inputyear/"."$firstletter/" . "$secondletter/"."$word";
    # print "$word $firstletter $secondletter $wordfilepath\n";
    # Skip if this file does not exist.  Possibly notate this somewhere.
    if (-e $wordfilepath) {
	print OUTFILE "open(INFILE,\"$wordfilepath\");\n";
	print OUTFILE "while (<INFILE>) {\n";
	print OUTFILE "$Output{$word}";
	print OUTFILE "}\n";
	print OUTFILE "close(INFILE);\n\n";

	$sizect+=length($Output{$word});
    }
}
close(OUTFILE);
`chmod 775 $outputfile`;

$date=`date`;
print "$date";
