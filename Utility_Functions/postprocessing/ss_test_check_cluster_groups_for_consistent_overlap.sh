#!/bin/bash 
#SBATCH -n 37
#SBATCH -p medium
#SBATCH -t 15:00:00
#SBATCH -o output.txt 
#SBATCH -e error.txt 
#SBATCH -N 1
module load matlab/R2024b
matlab -batch "test_check_cluster_groups_for_consistent_overlap; exit;"