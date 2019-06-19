
cd npl
./ocrtrim.sh
cat npl.1926.1976-patnplOCRautofix.tsv all.npl.cites | tr [:upper:] [:lower:] > npl.1926.2017-lowercaseOCRautofix.tsv
terracenpl.sh
cd ..

cd mag
#do the stata thing if you need to
bash fixnamesfornplmatch.sh 
bash breakbyearmag.pl mergedformag-fixednames.tsv
cd ..

cd wos
bash construct_raw_wos_with_issue.sh
bash breakbyearwos.pl wosplpubinfo1955-2017_filteredISS.txt

