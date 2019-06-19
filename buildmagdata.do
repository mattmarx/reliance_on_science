global maxnamelen (50)


import delimited ../txt/paperyear.txt, clear
rename v1 magid
rename v2 year
compress
format magid %15.0f
save ../dta/magyear, replace

import delimited using ../txt/papertype.tsv, clear
rename v1 magid
rename v2 papertype
compress
format magid %15.0f
save ../dta/magtype, replace
use ../dta/magtype, clear
keep if papertype=="Patent"
keep paperid
save ../dta/magpatents, replace


import delimited ../txt/paperjournalid.txt, clear
rename v1 magid
rename v2 journalid
compress
format magid %15.0f
save ../dta/magjournalid, replace

import delimited ../txt/Journals.txt, clear
rename v1 journalid
rename v4 journalname
keep journalid journalname
compress
save ../dta/journalnames, replace

import delimited ../txt/papersvolisspages.txt, clear
rename v1 magid
rename v2 volume
rename v3 issue
rename v4 firstpage
rename v5 lastpage
format magid %30.0f
compress
save ../dta/magvolisspages, replace

import delimited ../txt/Affiliations.txt, clear
drop v2 v4 v5 v6
rename v1 affiliationid
format affiliationid %15.0f
rename v3 affiliationame
compress
save ../dta/magaffiliationames, replace


import delimited using ../txt/conferenceseries.txt, clear
rename v1 conferenceid
rename v2 conferencename
compress
duplicates drop
save conferenceidname, replace

import delimited using ../txt/paperconferenceid.txt, clear
rename v1 magid
rename v2 conferenceid
merge m:1 conferenceid using conferenceidname, keep(3) nogen
compress
duplicates drop
drop conferenceid
save magconference, replace





import delimited ../txt/paperaffiliations.txt, clear
rename v1 magid
format magid %15.0f
rename v2 authorid
format authorid %15.0f
rename v3 affiliationid
format affiliationid %15.0f
rename v4 authororder
compress
save ../dta/magauthoraffiliation, replace


* save the list of author snames
import delimited ../txt/authorname.txt, clear
// drop v2 v4 v5 v6 v7
rename v1 authorid
rename v2 authorname
* DROP IF no letters in the name (it happens!)
drop if length(authorname)>100
compress
drop if !regexm(authorname, "[A-Za-z]")
* drop if >100 characters, probably a data erro
// duplicates drop authorid, force
compress
save authoridnames, replace

* dump out first authors with corrected names
use magid authorid authororder if authororder==1 using  magauthoraffiliation, clear
drop authororder
merge m:1  authorid using authoridnames, keep(3) nogen
drop authorid
duplicates drop magid, force
save mag1stauthorname, replace




import delimited using ../txt/papertitle-transliteratedgreek.tsv, clear
rename v1 magid
rename v2 papertitle
sort magid
drop if magid==magid[_n-1]
compress
save ../dta/magtitle, replace








***THIS IS EXTREMELY SLOW BECAUSE MANY NAMES ARE JARBLED NONSENSE HUNDREDS OF CHARACTERS
/*
insheet using ../txt/authorname-surnamefirst.txt, clear
rename v1 authorid
rename v2 authorname
drop if length(authorname)>70 // drops about 50k out of 22M but saves 50G in size
drop if !regexm(authorname, "[a-zA-Z]")
compress
d
save magauthornamesurfirst, replace
use magauthornamesurfirst, clear
rename authorname authorsurname
replace authorsurname = regexs(1) if regexm(authorsurname, "(.*),")
replace authorsurname = proper(authorsurname)
drop if regexm(lower(authorsurname), "anonymous")
merge 1:m authorid using magauthoraffiliation, keepusing(magid) nogen keep(3)
gen int authorsurnamefreq = 1
gcollapse (sum) authorsurnamefreq, by(authorsurname)
egen totalauthorsurnames = sum(authorsurnamefreq)
gen pctofauthorsurnames = authorsurnamefreq/total * 100
gsort -pctofauthorsurnames
gen ptile = (100*(_n-1)/_N)+1
gen authornamesurscalingfactor = min(1, (ptile - 1))
rename authorsurname authornamesur
keep authornamesur authornamesurscalingfactor pctofauthorsurnames
save magauthorsurnamefreq, replace
*/

import delimited ../txt/magcited5x.txt, clear
rename v1 magid
destring magid, replace force
drop if missing(magid)
duplicates drop
format magid %15.0f
save ../dta/magcited5x, replace
* make list of papers where some author is missing a name
use magauthoraffiliation, clear
drop affiliationid authororder
merge m:1 authorid using magauthorname, keep(1 3) keepusing()
drop authorname
gen missingauthor = _merge==1
keep if missingauthor==1
drop missingauthor _merge authorid
duplicates drop
save magpapersmissingauthornames, replace

* make list of papers where some author is missing a name
use ../dta/paperauthoraffiliation, clear
drop affiliationid authororder
merge m:1 authorid using ../dta/magauthorname, keep(1 3) keepusing()
drop authorname
gen missingauthor = _merge==1
keep if missingauthor==1
drop missingauthor _merge authorid
duplicates drop
save ../dta/magmissingauthornames, replace

* get citation file
* maybe hsould use PaperReferences but I am starting with same file as PaperCitationContexts
* otherwise we are probably putting ourselves at a disadvantage because we will throw out lots that are co-cited
import delimited ../txt/PaperReferences.txt, clear
rename v1 citingmagid
rename v2 citedmagid
duplicates drop
compress
save ../dta/magcitations, replace


* build this by running ../code/pullcocitations003.sh and pullcocitations-numbers001.sh on PaperCitationContexts
import delimited ../txt/cocitedpapersonly.txt, clear
rename v1 citingmagid
destring citingmagid, replace force
drop if missing(citingmagid)
format citingmagid %15.0f
rename v2 citedmagid
format citedmagid %15.0f
rename v3 cocitation
drop if ~regexm(cocitation, "[0-9a-zA-Z]")
duplicates drop
compress
save ../dta/magcocitedpapers, replace

import delimited using ../txt/PaperFieldsOfStudy.txt, colrange(1:2)
rename v1 magid
rename v2 fieldid
compress
save ../dta/magfields, replace
import delimited using ../txt/FieldsOfStudy.txt, clear
rename v1 fieldid
rename v2 fieldname
save fieldsofstudy, replace

keep magid
sort magid
drop if magid==magid[_n-1]
save ../dta/maghasfield, replace

import delimited ../txt/paperdoi.txt, clear
rename v1 magid
rename v2 doi 
drop if missing(magid)
drop if missing(doi)
compress
format magid %30.0f
save ../dta/magdoi, replace
