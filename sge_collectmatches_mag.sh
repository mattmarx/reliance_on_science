#$ -t 1799-2018
#$ -j y
#$ -N collectmatches
#$ -P marxnsf1

chmod 664 $SGE_STDOUT_PATH
chmod 664 $SGE_STDERR_PATH

cat /projectnb/marxnsf1/dropbox/bigdata/nplmatch/splittitle/year_regex_output_mag/year$SGE_TASK_ID-*.txt /projectnb/marxnsf1/dropbox/bigdata/nplmatch/splitcode/year_regex_output_mag/year$SGE_TASK_ID-*.txt | sort -u > /projectnb/marxnsf1/dropbox/bigdata/nplmatch/process_matches/peryearuniqmatches/mag/year$SGE_TASK_ID.txt


