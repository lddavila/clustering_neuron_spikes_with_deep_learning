#!/bin/bash 
#SBATCH -n 37
#SBATCH -p medium
#SBATCH -o output.txt 
#SBATCH -e error.txt 
#SBATCH -N 1
module load matlab/R2024b
matlab -batch "test_recursive_under_unit_grouping; exit;"