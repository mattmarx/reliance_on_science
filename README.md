The codes necessary to replicate [Marx/Fuegi 2019](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3331686) are contained in this directory. This code operates on, and assumes the presence of, a set of files from the Microsoft Academic Graph (MAG) and USPTO non-patent literature (NPL) references, described below. 

# DISCLAIMERS
The code is unsupported and is largely undocumented. It is provided primarily for those interested in understanding how the NPL linkages to MAG were accomplished. Moreover, it is executable only in a Sun Grid Engine (or similar) Unix environment with STATA installed as well as several packages including ftools and gtools and the Perl module Text::LevenshteinXS. It assumes the directory structure described below and contains hardcoded, fully-qualified pathnames. Moreover, you will need at least 5 terabytes of disk space, perhaps as much as 10.

There are four general steps in executing the matches: First, preparing the MAG data. Second, preparing the NPL data. Third, generating a first-pass set of "loose" matches. Fourth, scoring those "loose" matches and picking the best match for each NPL. Each of these major steps includes a number of sub-steps; there is no "master" script to run the process from beginning to end. 

# DIRECTORY STRUCTURE

Many of the programs assume /project/nb/marxnsf1/dropbox/ but this can be replaced by another prefix (but should be a fully-qualified pathname, not a relative reference – no environment variable is set to easily substitute, sorry). Beneath that directory, the necessary structure is:

- mag
- mag/code
- mag/dta
- mag/txt
- nplmatch
- nplmatch/inputs
- nplmatch/inputs/mag
- nplmatch/inputs/mag/magbyyear
- nplmatch/inputs/npl
- nplmatch/inputs/npl/nplbyrefyear
- nplmatch/inputs/journalabbrev
- nplmatch/splityear
- nplmatch/splitword
- nplmatch/splittitle
- nplmatch/splittitle/year_regex_scripts_mag
- nplmatch/splittitle/year_regex_output_mag
- nplmatch/splitcode
- nplmatch/splitcode/year_regex_scripts_mag
- nplmatch/splitcode/year_regex_output_mag
- nplmatch/process_matches
- nplmatch/process_matches/peryearuniqmatches
- nplmatch/process_matches/peryearuniqmatches/mag
- nplmatch/process_matches/pieces
- nplmatch/sort_scored_matches
 
# PROGRAMS TO RUN
## STEP 1: PREPARE MAG FILES
1. download from MAG the following files into the mag/txt directory: Papers.txt, ConferenceSeries.txt, Journals.txt, Authors.txt, and Affiliations.txt. Instructions for accessing MAG are [here](https://www.microsoft.com/en-us/research/project/microsoft-academic-graph/). You will need to create an Azure account in order to download the files. You may be able to download a recent snapshot [here](https://zenodo.org/record/2628216#.XRJHwIGSlGo).
1. in the mag/txt directory, execute the script _createsubsets_tsv_nochopNOPAT.sh_ to create a number of derivative files from the MAG originals in the mag/txt directory. 
1. in the mag/txt directory, run _"cat papertitle.tsv | translategreekletters.sh > papertitle-transliteratedgreek.tsv"_ to write out all greek characters in MAG titles as alphas. 
1. in the mag/txt directory, run _fixauthornames.sh_ to reverse the order of first and last names in the MAG data.  This calls process_lastnames-justauthoridname.pl from mag/code to create authorname-fixed.txt and authorname-surfirst.txt in the mag/txt directory.
1. execute the Stata script _buildmagdata.do_ in the mag/code directory. This will read a number of files from mag/txt and output stata-formatted versions of them in mag/dta.
1. in the nplmatch/inputs/mag directory, execute the Stata script _dumpmagfieldsfornpl.do_. This will combine the individual MAG files from mag/dta and write them out in a single mergedmagfornpl.dta file in the nplmatch/inputs/mag directory as well as a tab-delimited mergedmagfornpl.tsv file.
1. in the nplmatch/inputs/mag directory, run _fixnamesfornplmatch.sh_ to lowercase the MAG files and swap the order of given and surnames in the author field. this creates a file mergedmagfornpl-fixednames.tsv.
1. in the nplmatch/inputs/mag directory, run _terracemag.sh_ to split up the MAG papers by year into nplmatch/inputs/mag/magbyyear.



## STEP 2: PREPARE NPL FILES
1. download and extract the "otherreference" file from Patentsview (www.patentsview.org/download - depending on the release date, the exact URL to the file may change.) copy the extracted file otherreference.tsv to this directory.
1. type the command _"cut -f2,3 otherreference.tsv > npl.1976-present.tsv"_ to extract just the fields needed.
1. in nplmatch/inputs, run the command _"cat npl.1926.1975.tsv | ocrtrim.sh | ocrnpldash.pl > npl.1926.1975-patnplOCRautofix.tsv"_ to clean up OCRed NPLs prior to 1976.
1. in nplmatch/inputs, run the command _"cat npl.1926.1975-patnplOCRautofix.tsv npl.1976-present.tsv | tr [:upper:] [:lower:] | perl screen_npljunk.pl > npl.1926.2018-lowercaseOCRautofixnononsci.tsv"_ to combine the NPL files, lowercase them, and strip out the bulk of references not to papers but random things like websites, product brochures, etc.
1. in nplmatch/inputs, run _terracenpl.sh_ to split the combined NPLs into individual years as well as a "fake" year, 1799, for NPLs with no year in them. All of these files are placed in nplmatch/inputs/nplbyrefyear.


## STEP 3: DO THE "LOOSE" FIRST-PASS MATCHING
1. copy the files journalabbrevs.tsv and journalabbrevs-extended.tsv to the nplmatch/inputs/journalabbrev.
1. copy the files commonsurnames.csv, verycommonsurnames.csv, probablyonlywords.txt to nplmatch/process_matches.
1. in nplmatch/splitword, run _splitword.sh_ to submit an array job that runs splitword.pl for each year from 1800-2018. This creates a hash of all words in the NPLs in subdirectories of nplmatch/splitword such as '1980/a/c/achieve' containing all 1980 NPLs that include the word "ahieve"
1. in nplmatch/splittitle, run _"buildtitleregex_1799_lev.pl mag"_ to generate rules for NPLs without years in nplmatch/splittitle/year_regex_scripts_mag.  These rules are based on primary author surname in MAG and finding either the longest or second longes word in the title.
1. in nplmatch/splittitle, run _sge_buildtitleregex_magLEV.sh_ to generate rules for NPLs with years in nplmatch/splittitle/year_regex_scripts_mag.  These rules are based on primary author surname in MAG and finding either the longest or second longes word in the title.
1. in nplmatch/splittitle, run _set_sge_lev_mag_splittitle.sh_ to simultaneously apply the generated rules against the NPL data
1. in nplmatch/splityear, run _splityear.sh_ to submit an array job that runs splityear.pl for each year from 1800-2018.  This creates a hash of all number in the NPLs in subdirectories of nplmatch/splityear such as '1963/1/15330' contaning all 1963 NPLs that incldue the number 15330. 
1. in nplmatch/splitcode, run _"buildsplitregex_1799_lev.pl mag"_ to generate matching rules without titles for NPLs missing years.  These rules are based on primary author surname in MAG and finding the first page of the article (or volume if there is no first page in MAG).
1. in nplmatch/splitcode, run _sge_buildsplitregex_lev_mag.sh_ to generate matching rules without titles for NPLs with years.  These rules are based on primary author surname in MAG and finding the first page of the article (or volume if there is no first page in MAG).
1. in nplmatch/splitcode, run _set_sge_lev_mag_splitcode.sh_ to launch thousands of simultaneous scripts to apply the generated rules against the NPL data.

## STEP 4: GATHER THE "LOOSE" MATCHES AND SCORE THEM
1. in nplmatch/process_matches, run _sge_collectmatches_mag.sh_ to gather the output of the loose-match processes (both title-based and non-title-based) into nplmatch/process_matches/peryearuniqmatches/mag/, one file per year (and one file for missing years).  This process also sorts the matches and removes duplicates.
1. in nplmatch/process_matches, run _"cat peryearuniqmatches/mag/* > bothmatchestoscore_mag.tsv"_ to combine the matches for each year into a single file
1. run _score_matches_mag.sh_, which scores the loosematches and retains all matches for every NPL (with confidence score >0) in scoredmag.tsv. It splits bothmatchestoscore_mag.tsv into hundreds of smaller, parallelizable pieces in nplmatch/process_matches/pieces. 
1. copy or move scoredmag.tsv from nplmatch/process_matches to nplmatch/sort_scored_matches.
1. in nplmatch/sort_scored_matches, run _sort_scored_mag.sh_ to pick the best match for each NPL from those with confidence score > 0, creating the output file scoredmag_bestonly.tsv (and along the way, scoredmag_sorted.tsv, though this file can be ignored).

