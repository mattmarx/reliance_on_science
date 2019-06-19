#<ctrl v><tab> to do the tab
echo "sorting internally"
sort -t"	" -k19,20 scoredmag.tsv | uniq > scoredmag_sorted.tsv
echo "picking best"
findbest_match.pl scoredmag_sorted.tsv > scoredmag_bestonly.tsv
rm -f scoredmag_sorted.tsv
