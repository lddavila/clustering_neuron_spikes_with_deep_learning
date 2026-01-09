#!/bin/bash 
#SBATCH -n 40
#SBATCH -p medium
#SBATCH -J noise_lvls
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "concatenate_all_available_bp_tables_into_one;exit()"