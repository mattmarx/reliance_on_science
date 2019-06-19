#!/bin/bash
#$ -P marxnsf1
#$ -j y
#$ -t 1800-2018
#$ -N splitword

splitword.pl $SGE_TASK_ID
chmod 664 $SGE_STDOUT_PATH

