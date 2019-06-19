#!/bin/bash -l

#$ -t 1800-2018
#$ -m a
#$ -j y
#$ -N buildtitleregex_mag
#$ -l h_rt=24:00:00
#$ -P marxnsf1

chmod 664 $SGE_STDOUT_PATH
chmod 664 $SGE_STDERR_PATH


/projectnb/marxnsf1/dropbox/bigdata/nplmatch/splittitle/buildtitleregex_byyear_lev.pl mag $SGE_TASK_ID


