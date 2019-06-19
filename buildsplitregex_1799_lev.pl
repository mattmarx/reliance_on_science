#!/usr/local/bin/perl

$filesize=25000000;
$inputyear="1799";
$specialcase=50;

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
	die("Usage: buildsplitregex_1799.pl mag|wos|filename_or_fullpath_of_file\n");
    }
}

print "Using source directory/file: $inputfile  Sourcecode: $sourcefilecode\n\n";

open(INFILE,$inputfile)||die("Can't open input file $inputfile");
# space separates patent & ref for the master NPL
# tab separates patent & ref for the yearly slices (and has the year at the end, which could create false positives

$outputdir="/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splitcode/year_regex_scripts_" . "$sourcefilecode". "/";;

$inputdir="/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splityear/";

$date=`date`;
print "$date";

chdir("/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splitcode");

$linect=0;
while (<INFILE>) {
    $line=$_;

    $linect++;
    if (($linect % 100000)==0) {
	print "At line $linect\n";
    }


    #print $_;
    chop($line);
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
	$firstpage =~ s/\///;
	$lastpage =~ s/\///;
	$issue =~ s/\///;
	$vol =~ s/\?//;
	$firstpage =~ s/\?//;
	$lastpage =~ s/\?//;
	$issue =~ s/\?//;
	$vol =~ s/\(//;
	$firstpage =~ s/\(//;
	$lastpage =~ s/\(//;
	$issue =~ s/\(//;
	$vol =~ s/\)//;
	$firstpage =~ s/\)//;
	$lastpage =~ s/\)//;
	$issue =~ s/\)//;
	$title=~s/[^a-zA-Z0-9-,'.(): ]//g;
	$title_print=$title;
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

	# Skip items with No author, "[anonymous]" author, before 1800, or after 2018
	# MMADD change this to 1799 to accommodate the no-year NPs
	if (($firstauthor_lastname eq "")||($firstauthor_lastname eq "[anonymous]")||($year<1799)||($year>2018)) { next; }

	$matchnumber=$firstpage;
	if (!$matchnumber) { $matchnumber=$vol; }
	
	# Skip authors with no alphanumerics
	if ($firstauthor=~/\w/) {
	    if ($matchnumber) {
		if (length($firstauthor_lastname)>=4) {
		    $output="$wosid\t$year\t$vol\t$issue\t$firstpage\t$lastpage\t$firstauthor\t$title_print\t$journal\t";
		    $regex="\t&fullcompare(\$\_,\"$firstauthor_lastname\",\"$output\");\n";
		}
		else {
		    $regex= "\tif (/\[\^a\-zA\-Z0\-9\_\-\]$firstauthor_lastname\[\^a\-zA\-Z0\-9\_\-\]/) { print \"$wosid\t$year\t$vol\t$issue\t$firstpage\t$lastpage\t$firstauthor\t$title_print\t$journal\t\$_\"; }\n";
		}
		$Output{$matchnumber}.=$regex;
	    }
	}
    }
    else {
	print "No format match found for line $linect - $line\n";
    }
}

print "\n";


# Perl line and fullcompare function to support Levenshtein distance
open(PERLFILE,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splittitle/template_perl")||die("Can't open Perl Template file template_perl\n");
$template_contents="";
while(<PERLFILE>) {
    $template_contents.="$_";
}
close(PERLFILE);

$sizect=$filesize;
$filect=0;
# Special handling for low numbers
for($lownum=1;$lownum<=$specialcase;$lownum++) {
    $lownum_output=$Output{"$lownum"};
    @lines="";
    @lines=split(/\n/,$lownum_output);
    $numlines=@lines;
    $sizect=$filesize;
    for($i=0;$i<$numlines;$i++) {
	if ($sizect>=($filesize/6)) { # Because the comparison on the other side for low numbers is also much larger, treat the file size limit for them as being 1/6 as big as for other numbers.
	    $sizect=0;
	    $filenum=$filect+1000;
	    if ($filect!=0) { 
		print OUTFILE "}\n";
		print OUTFILE "close(INFILE);\n\n";
		
		close(OUTFILE); 
		`chmod 775 $outputfile`;
	    }
	    $outputfile="$outputdir"."year"."$inputyear"."-"."$filenum".".pl";
	    open(OUTFILE,">$outputfile");

	    print OUTFILE "$template_contents\n";
	    
	    $firstchar=substr($lownum,0,1);
	    $pagevolfilepath="$inputdir"."$inputyear/"."$firstchar"."/"."$lownum";
	    print OUTFILE "open(INFILE,\"$pagevolfilepath\");\n";
	    print OUTFILE "while (<INFILE>) {\n";
	    
	    $filect++;
	}

	print OUTFILE "$lines[$i]\n";
	$sizect+=length($lines[$i]);
    }
}

# Handle final file closing. Then continue on to other numbers
print OUTFILE "}\n";
print OUTFILE "close(INFILE);\n\n";

close(OUTFILE); 
`chmod 775 $outputfile`;

$sizect=$filesize;

foreach $matchnumber (keys %Output) {
    if (($matchnumber>=1)&&($matchnumber<=$specialcase)) { next; } # Handled above.
    if ($sizect>=$filesize) {
	$sizect=0;
	$filenum=$filect+1000;
	close(OUTFILE); 
	`chmod 775 $outputfile`;
	$outputfile="$outputdir"."year"."$inputyear"."-"."$filenum".".pl";
	open(OUTFILE,">$outputfile");
	# Perl line and fullcompare function to support Levenshtein distance
	open(PERLFILE,"/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splittitle/template_perl")||die("Can't open Perl Template file template_perl\n");
	while(<PERLFILE>) {
	    print OUTFILE "$_";
	}
	close(PERLFILE);

	$filect++;
    }
    $firstchar=substr($matchnumber,0,1);
    $pagevolfilepath="$inputdir"."$inputyear/"."$firstchar/"."$matchnumber";
    # Skip if this file does not exist.  Possibly notate this somewhere.
#    print "Matchnumber $matchnumber\n\t$firstchar\t$pagevolfilepath\n";
    if (-e $pagevolfilepath) {
	print OUTFILE "open(INFILE,\"$pagevolfilepath\");\n";
	print OUTFILE "while (<INFILE>) {\n";
	print OUTFILE "$Output{$matchnumber}";
	print OUTFILE "}\n";
	print OUTFILE "close(INFILE);\n\n";

	$sizect+=length($Output{$matchnumber});
    }
}
close(OUTFILE);
`chmod 775 $outputfile`;

$date=`date`;
print "$date";
