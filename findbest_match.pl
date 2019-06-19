#!/share/pkg/perl/5.24.0/install/bin/perl

use Text::LevenshteinXS qw(distance);

# Sort order:
# 1 Confidence
# 2 Title Percentage
# 3 Best Title Percentage
# 4 VIP Score
# 5 Minimum Levenshtein Distance
# 6 Highest Journal Score
# 7 If one journal 'cheminform' and other not, use one that is NOT


$debug=1;

$inputfile=$ARGV[0];
if (!$inputfile) { print "Usage: findbest_match.pl INPUTFILE\n"; }
open(INFILE,"$inputfile")||die("Input file $inputfile not found.\n");
@lines=<INFILE>;
$numlines=@lines;

($refsource,$confidence,$volisspage_score,$title_score,$levmindist,$percentage,$bestpercent,$perfectuntil,$journal_score,$wosid,$year,$vol,$issue,$firstpage,$lastpage,$firstauthor,$title,$journal,$patentid,$patentline,@rest)=split(/\t/,$lines[0]);
$line=$lines[0];
&BackupFields();
for($i=1;$i<=$numlines;$i++) {
    $line=$lines[$i];
    ($refsource,$confidence,$volisspage_score,$title_score,$levmindist,$percentage,$bestpercent,$perfectuntil,$journal_score,$wosid,$year,$vol,$issue,$firstpage,$lastpage,$firstauthor,$title,$journal,$patentid,$patentline,@rest)=split(/\t/,$line);

    # Doesn't match so print the best current line, store this line's data, and
    # move on.
    if (($patentid ne $oldpatentid)||($patentline ne $oldpatentline)) {
	print "$bestline";

	# Save this data
	&BackupFields();

	next;
    }


    # Determine if new line is better than patent-data-matching earlier line.
    if ($oldconfidence>$confidence) { next; }
    elsif ($confidence>$oldconfidence) {
	# Save this data
	&BackupFields();

	next;
    }
    # Equal confidence so keep going

    if ($oldpercentage>$percentage) { next; }
    elsif ($percentage>$oldpercentage) {
	# Save this data
	&BackupFields();

	next;
    }    
    # Equal TitlePct so keep going

    if ($oldbestpercent>$bestpercent) { next; }
    elsif ($bestpercent>$oldbestpercent) {
	# Save this data
	&BackupFields();

	next;
    }    
    # Equal BestPercent so keep going

    if ($oldvolisspage_score>$volisspage_score) { next; }
    elsif ($volisspage_score>$oldvolisspage_score) {
	# Save this data
	&BackupFields();

	next;
    }    
    # Equal VolIssuePage Score so keep going

    if (($oldlevmindist<10)||($levmindist<10)) {
	if ($oldlevmindist>$levmindist) { next; }

	elsif ($levmindist>$oldlevmindist) {
	    # Save this data
	    &BackupFields();

	    next;
	}    
    }
    # Equal or both very bad Levenshtein Min Distance so keep going

    if ($oldjournal_score>$journal_score) { next; }
    elsif ($journal_score>$oldjournal_score) {
	# Save this data
	&BackupFields();

	next;
    }    
    # Equal Journal Score so keep going

    # Most recent year.  Skip for now
    # if ($oldyear>$year) { next; }
    # elsif ($year>$oldyear) {
	# Save this data
	# &BackupFields();

	# next;
    # }    
    # Equal Year so keep going

    # If one journal is 'cheminform' and the other is not, use the one that is NOT 'cheminform'
    if ((!($oldjournal eq "cheminform"))&&($journal eq "cheminform")) { next; }
    elsif ((!($journal eq "cheminform"))&&($oldjournal eq "cheminform")) { 
	# Save this data
	&BackupFields();

	next;
    }    

    # If we get all the way to here, just keep the earlier one.
}

sub BackupFields {
    $oldconfidence=$confidence;
    $oldvolisspage_score=$volisspage_score;
    $oldtitle_score=$title_score;
    $oldlevmindist=$levmindist;
    $oldpercentage=$percentage;
    $oldbestpercent=$bestpercent;
    $oldperfectuntil=$perfectuntil;
    $oldjournal_score=$journal_score;
    $oldwosid=$wosid;
    $oldyear=$year;
    $oldvol=$vol;
    $oldissue=$issue;
    $oldfirstpage=$firstpage;
    $oldlastpage=$lastpage;
    $oldjournal=$journal;
    $oldpatentid=$patentid;
    $oldpatentline=$patentline;
    $bestline=$line;
}
