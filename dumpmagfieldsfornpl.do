global magdir "../../../mag/dta/"
use $magdir/magtitle, clear
merge 1:1 magid using $magdir/magyear, keep( 1 3) nogen
rename magid paperid
merge 1:1 paperid using $magdir/magtype, keep(1 3) nogen
drop if papertype=="Patent"
drop papertype
rename paperid magid
duplicates drop magid, force
merge 1:1 magid using $magdir/magvolisspages, keep(1 3) nogen
merge m:1 magi using $magdir/mag1stauthorname, keep(1 3) nogen
merge 1:1 magid using $magdir/magjournalid, keep(1 3) nogen
merge m:1 journalid using $magdir/journalnames, keep(1 3) nogen
drop journalid
merge 1:1 magid using $magdir/magconference, keep(1 3) 
replace journal = conferencename if missing(journal) & !missing(conferencename)
compress
save mergedmagfornpl, replace
use mergedmagfornpl, clear
export delimited year magid volume issue firstpage lastpage authorname papertitle journalname using mergedmagfornpl.tsv, replace delim(tab)

 
