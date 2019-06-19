#!/bin/bash -l

#$ -t 10868-10868
#$ -j y
#$ -N minpltitle
#$ -l h_rt=12:00:00
#$ -P marxnsf1

chmod 664 $SGE_STDOUT_PATH
chmod 664 $SGE_STDERR_PATH


qsubstata.sh soundexmatchalltitlespieces $SGE_TASK_ID

