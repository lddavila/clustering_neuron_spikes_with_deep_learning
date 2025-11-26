#!/bin/bash 
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -p medium
#SBATCH -J find_grouping_faliures
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "get_grouping_for_specific_unit_and_recording();exit;"