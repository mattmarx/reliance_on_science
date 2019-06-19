#/bin/bash -x
echo "combining npls early and late"

#loop from 1900 (earliest WOS; MAG has back to 1800) until present
for year in {1800..2018}
do
 echo "looking for papers published in year $year"
 cat nplsnotmatchedwtitles.tsv | grep "[^0-9]$year[^0-9]" > nplsnotfoundbyyear/nplc_$year.tsv 
done
