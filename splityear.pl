#!/usr/local/bin/perl

$maxnumber="100000";

$year=$ARGV[0];
$infile="/projectnb/marxnsf1/dropbox/bigdata/nplmatch/inputs/npl/nplbyrefyear/nplc_$year" . ".tsv";
if (!$year) { die "Usage: splityear.pl YEAR\n"; }

open(INFILE,"$infile")||die("Can't open infile $infile.\n");

$outdir="/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splityear/$year";
if (!(-e $outdir)) {
    mkdir($outdir);
    `chmod 775 $outdir`;

    for($i=0;$i<10;$i++) {
	$dirname="$outdir" . "/" . "$i";
	if (!(-e $dirname)) {
	    mkdir($dirname);
	    `chmod 775 $dirname`;
	}
    }
}

$date=`date`;
print "$date";

$linect=0;
while(<INFILE>) {
    $line=$_;

    $linect++;
    if (($linect % 10000)==0) {
	print "At line $linect\n";
    }
    $rest=substr($line,8); # Drop the patent number
    $rest=~s/[^0-9]$year[^0-9]//; # Drop one instance of the year 

    # Make an array of all the numbers remaining in the line.
    $rest=~s/[^0-9]/ /g; 
    $rest=~s/^\s+//;
    @numbers="";
    @numbers=split(/\s+/,$rest);
    @numbers = sort { $a <=> $b } @numbers;

    # Append this line to the file for each number referenced.
    $prevnumber=10000000;
    foreach $number (@numbers) {
	if ($number==$prevnumber) { next; }
	if ($number>$maxnumber) { next; }
	$Output{$number}.=$line;
    }
}

foreach $key (keys %Output) {
    $firstchar=substr($key,0,1);
    open(OUTFILE,">$year/$firstchar/$key");
    print OUTFILE "$Output{$key}";
    close(OUTFILE);
    `chmod 664 $year/$firstchar/$key`;
}

$date=`date`;
print "$date\n";
