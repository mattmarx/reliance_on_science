#/bin/bash -x

#loop from 1800 () until present
for year in {1800..2017}
do
 echo "looking for papers published in year $year"
 cat mergedmagfornpl-fixednames.tsv | grep "^$year" > magbyyear/mag_$year.tsv 
done

