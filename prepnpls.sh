#!/bin/bash

./ocrtrim.sh
cat npl.1926.1975-patnplOCRautofix.tsv npl.1976-2017.tsv npl.2018.tsv  | tr [:upper:] [:lower:] | perl screen_npljunk.pl > npl.1926.2018-lowercaseOCRautofix.tsv
#cat npl.1926.1975-patnplOCRautofix.tsv npl.1976-2017.tsv npl.2018.tsv  | tr [:upper:] [:lower:]| grep -f nonscinpl.txt -v > npl.1926.2017-lowercaseOCRautofix.tsv
./terracenpl.sh

