cat mergedmagfornpl-fixednames.tsv | cut -f1,7 | sed -e 's/,.*//' | sort | uniq -c > magyearauthorfreq.tsv
