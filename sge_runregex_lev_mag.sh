#!/bin/bash -l

#$ -t 1800-2018
#$ -j y
#$ -N volissmag
#$ -l h_rt=24:00:00
#$ -P marxnsf1

chmod 664 $SGE_STDOUT_PATH
chmod 664 $SGE_STDERR_PATH


/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splitcode/year_regex_scripts_mag/year$SGE_TASK_ID-1000.pl > /projectnb/marxnsf1/dropbox/bigdata/nplmatch/splitcode/year_regex_output_mag/year$SGE_TASK_ID.txt


