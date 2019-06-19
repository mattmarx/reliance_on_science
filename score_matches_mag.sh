OPT=$1
if [ "$OPT" = "skipsplit" ]
then
 echo "not splitting"
else 
 split -d -l1000000 -a 4 --verbose bothmatchestoscore_mag.tsv toscoremag_1
 rm -f pieces/toscoremag_1*
 mv toscoremag_1* pieces/
fi
rm -f pieces/scoredmag*
rm -f scoredmag.tsv
num=$( ls -1 pieces/toscoremag_* | wc -l)
num=$(perl -e "print 10000+$num")
echo "10000-$num"
qsub -t 10000-$num sge_score_matches_mag.sh
# when that is done
qsub -N combscoremag -hold_jid scoremag -o scoredmag.tsv  -b y "cat pieces/scoredmag_* | fgrep -v toscoremag_1 | fgrep -v VolIssPageScore | sort -u"

