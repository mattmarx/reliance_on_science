cat mergedmagfornpl.tsv | grep -v papertitlejournalname |  iconv -f UTF8 -t US-ASCII//TRANSLIT | tr [:upper:] [:lower:] > mergedmagfornpl-ascii.tsv
perl process_lastnames.pl mergedmagfornpl-ascii.tsv | sort  > mergedmagfornpl-fixednames.tsv
perl breakbyearmag.pl mergedmagfornpl-fixednames.tsv
