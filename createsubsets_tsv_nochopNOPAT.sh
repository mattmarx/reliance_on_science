# make a list of mag patents
cut -f1,4 Papers.txt | fgrep Patent | cut -f1 | sort > magpatents.txt
sort Papers.txt > Papersorted.txt

join -a 1 -v 1 -t $'\t' Papersorted.txt magpatents.txt > PapersNOPATS.txt

#get the IDs for papers, journals, and conferences
echo -e "paperid\tpaperyear" > paperyear.tsv
cat PapersNOPATS.txt | cut -f1,8 >> paperyear.tsv
echo -e "paperid\tjournalid" > paperjournalid.tsv
cat PapersNOPATS.txt | cut -f1,11 >> paperjournalid.tsv
echo -e "paperid\tconferenceid" > paperconferenceid.tsv
cat PapersNOPATS.txt | cut -f1,12 >> paperconferenceid.tsv
echo -e "paperid\tpapervolume\tpaperissue\tpaper1stpage\tpaperlastpage" > papervolisspages.tsv
cat PapersNOPATS.txt | cut -f1,14,15,16,17 >> papervolisspages.tsv

# get the conference id + name to merge
echo -e "conferenceid\tconferencename" > conferenceidname.tsv
cat ConferenceSeries.txt | cut -f1,4 >> conferenceidname.tsv

# journals
echo -e "journalid\tjournalname" > journalidname.tsv
cat Journals.txt | cut -f1,3,4 >> journalidname.tsv


# author names
echo -e "authorid\tauthorname_normalized" > authoridname_normalized.tsv
cat Authors.txt | cut -f1,3 >> authoridname_normalized.tsv
echo -e "authorid\tauthorname_raw" > authoridname_raw.tsv
cat Authors.txt | cut -f1,4 >> authoridname_raw.tsv

#titles
echo -e "paperid\tpapertitle" > papertitle.tsv
cat PapersNOPATS.txt | cut -f1,5 >> papertitle.tsv

