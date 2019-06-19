#/bin/bash -x
# combined npls
echo "combining npls early and late"
#cat npl.1926.1975-lowercase.tsv uspto.citation.npl-lowercase.tsv > npl1926-2017.tsv

#loop from 1900 (earliest WOS; MAG has back to 1800) until present
for year in {1800..2018}
do
 echo "looking for papers published in year $year"
 cat npl.1926.2018-lowercaseOCRautofixnononsci.tsv | grep "[^0-9]$year[^0-9]" > nplbyrefyear/nplc_$year.tsv 
done
# hack for the NPLs that don't have a year
echo "now collect the non-nonsci NPLS without years and call them 1799"
 cat npl.1926.2018-lowercaseOCRautofixnononsci.tsv | perl nplnoyear.pl > nplbyrefyear/nplc_1799.tsv
