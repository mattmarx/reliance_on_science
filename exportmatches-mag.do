global version "20190522"

* prepare the full table with all matches + npl line
use patent reftype nplwithoutpatent magid confscore if confscore>2 using scoredmaglatest$version, clear
rename magid paperid
export delimited  using pcsallplusnpl$version.tsv, delim(tab) replace
drop nplwithoutpatent
export delimited using pcs$version.tsv, delim(tab) replace
/*
* prepare the tables for most users with patent/magid, no duplicates
gen hasjournal = !missing(journal)
gen journalnotconf = 1
foreach x in conference meeting symposium proceedings {
 replace journalnotconf = 0 if regexm(journal, "`x'")
}
// foreach x in titlepct vipscore bestitle year hasjournal journalnotconf {
//  bys patent nplwithoutpatent: egen max`x' = max(`x')
// }
bys patent nplwithoutpatent: egen maxtitlepct = max(titlepct)
keep if titlepct==maxtitlepct
bys patent nplwithoutpatent: egen maxbesttitle = max(bestitle)
keep if bestitle==maxbestitle
bys patent nplwithoutpatent: egen maxvipscore = max(vipscore)
keep if vipscore==maxvipscore
bys patent nplwithoutpatent: egen maxyear = max(year)
keep if year==maxyear
bys patent nplwithoutpatent: egen maxhasjournal = max(hasjournal)
keep if hasjournal==maxhasjournal
bys patent npl: gen numatches = _N
bys patent nplwithoutpatent: egen maxjournalnotconf = max(journalnotconf)
drop if journalnotconf~=maxjournalnotconf & numatches>1
drop numatches
bys patent npl: gen numatches = _N
bys patent npl: egen numtitles = nvals(title)
sort patent npl
drop if patent==patent[_n+1] & magid==magid[_n+1] & numtitles>1
rename magid paperid
keep patent reftype paperid confscore
duplicates drop
compress
save uniquepcs$version, replace
export delimited using pcsunique$version.tsv, delim(tab) replace
