# make a list of mag patents
cut -f1,4 Papers.txt | fgrep Patent | cut -f1 | sort > magpatents.txt
sort Papers.txt > Papersorted.txt
sort PaperAuthorAffiliations.txt > PaperAuthorAffiliationsorted.txt
sort PaperReferences.txt > PaperReferencesorted.txt

join -a 1 -v 1 -t $'\t' Papersorted.txt magpatents.txt > PapersNOPATS.txt
join -a 1 -v 1 -t $'\t' PaperAuthorAffiliationsorted.txt magpatents.txt > PaperAuthorAffiliationsNOPAT.txt
join -a 1 -v 1 -t $'\t' PaperReferencesorted.txt magpatents.txt > PaperReferencesNOPAT.txt

#get the IDs for papers, journals, and conferences
echo -e "paperid\tdoi" > paperdoi.tsv
cat PapersNOPATS.txt | cut -f1,3 >>paperdoi.tsv
zip paperdoi.zip paperdoi.tsv
echo -e "paperid\tpaperyear" > paperyear.tsv
cat PapersNOPATS.txt | cut -f1,8 >> paperyear.tsv
zip paperyear.zip paperyear.tsv
echo -e "paperid\tjournalid" > paperjournalid.tsv
cat PapersNOPATS.txt | cut -f1,11 >> paperjournalid.tsv
zip paperjournalid.zip paperjournalid.tsv
echo -e "paperid\tconferenceid" > paperconferenceid.tsv
cat PapersNOPATS.txt | cut -f1,12 >> paperconferenceid.tsv
zip paperconferenceid.zip paperconferenceid.tsv
echo -e "paperid\tpapervolume\tpaperissue\tpaper1stpage\tpaperlastpage" > papervolisspages.tsv
cat PapersNOPATS.txt | cut -f1,14,15,16,17 >> papervolisspages.tsv
zip papervolisspages.zip papervolisspages.tsv

# get the conference id + name to merge
echo -e "conferenceid\tconferencename" > conferenceidname.tsv
cat ConferenceSeries.txt | cut -f1,4 >> conferenceidname.tsv
zip conferenceidname.zip conferenceidname.tsv

# journals
echo -e "journalid\tjournalname" > journalidname.tsv
cat Journals.txt | cut -f1,3,4 >> journalidname.tsv
zip journalidname.zip journalidname.tsv


# authoridaffiliationid
echo -e "paperid\tauthorid\tauthororder" > paperauthororder.tsv
cut -f1,2,4 PaperAuthorAffiliationsNOPAT.txt >> paperauthororder.tsv
zip paperauthororder.zip paperauthororder.tsv
echo -e "paperid\tauthorid\taffiliationame" > paperauthoridaffiliationname.tsv
cut -f1,2,5 PaperAuthorAffiliationsNOPAT.txt | grep [a-zA-Z] >> paperauthoridaffiliationname.tsv
zip paperauthoridaffiliationname.zip paperauthoridaffiliationname.tsv
# author names
echo -e "authorid\tauthorname_normalized" > authoridname_normalized.tsv
cat Authors.txt | cut -f1,3 >> authoridname_normalized.tsv
zip authoridname_normalized.zip authoridname_normalized.tsv
echo -e "authorid\tauthorname_raw" > authoridname_raw.tsv
cat Authors.txt | cut -f1,4 >> authoridname_raw.tsv
zip authoridname_raw.zip authoridname_raw.tsv



# fields of study
echo -e "fieldid\tfieldname" > fieldidname.tsv
cat FieldsOfStudy.txt | cut -f1,3,4 >> fieldidname.tsv
zip fieldidname.zip fieldidname.tsv
echo -e "paperid\tfieldid" > paperfieldid.tsv
cat PaperFieldsOfStudy.txt | cut -f1,2 >> paperfieldid.tsv
zip paperfieldid.zip paperfieldid.tsv

#citations
echo -e "citingpaperid\tcitedpaperid" > papercitations.tsv
cat PaperReferencesNOPAT.txt >> papercitations.tsv
zip papercitations.zip papercitations.tsv

#titles
echo -e "paperid\tpapertitle" > papertitle.tsv
cat PapersNOPATS.txt | cut -f1,5 >> papertitle.tsv
zip papertitle.zip papertitle.tsv

cp *.zip ~/sccpc/transfer/
