#!/bin/bash 
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -p medium
#SBATCH -J group
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch 'train_nets_to_id_above_and_below_with_grades();exit;'