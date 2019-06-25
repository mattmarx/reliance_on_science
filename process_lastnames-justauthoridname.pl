#!/usr/local/bin/perl

open(INFILE,"$ARGV[0]")||die("Usage: process_lastnames.pl FILENAME\n");

open(PREFIXES,"lastname_prefixes.txt");
while(<PREFIXES>) {
    $prefix=$_;
    chop($prefix);
    push(@prefixes,$prefix);
}

while(<INFILE>) {
    $line=$_;
    chop($line);
#print STDERR "$line\n";
    @lineparts=split(/\t/,$line);

    $author=$lineparts[1];
    @parts=split(/\s+/,$author);
    $lastpart=@parts-1;
    
    $lastname=$parts[$lastpart];
    if (($lastpart>=2)&&($parts[$lastpart-2] eq "van")&&($parts[$lastpart-1] eq "der")) {
	$lastpart-=2;	 
	$lastname="$parts[$lastpart-2] $parts[$lastpart-1] $lastname";   
    }
    elsif (($lastpart>=1)&&(&member($parts[$lastpart-1],@prefixes))) {
	$lastname="$parts[$lastpart-1] $lastname";
	$lastpart--;
    }
    
    $firstpartofname="";
    for($i=0;$i<$lastpart;$i++) {
	$firstpartofname.="$parts[$i] ";
    }
    $firstpartofname=~s/ $//;
    $fullname="$lastname" . ", " . "$firstpartofname";

    $skip="";
    if ((length($lastname)<=1)||($lastname=~/\?/)) { $skip="SKIP"; }

    if ($firstpartofname) {
#	printf("%-35s %-35s %4s\n",$author,$fullname,$skip);
	$lineparts[1]=$fullname;
    }
    else {
#	printf("%-35s %-35s %4s\n",$author,$lastname,$skip);
	$lineparts[1]=$lastname;
    }

    $newline=join("\t",@lineparts);

    if (!$skip) {
	print "$newline\n";
    }
}


#Called by the form &member($item,@list) and returns "yes" if $item is a member
#of the list @list.
sub member {
    my($search,@inlist)=@_;
    $retval="";
    foreach $item (@inlist) {
        if ("$item" eq "$search") { $retval="yes"; }
    }

    $retval;
}
