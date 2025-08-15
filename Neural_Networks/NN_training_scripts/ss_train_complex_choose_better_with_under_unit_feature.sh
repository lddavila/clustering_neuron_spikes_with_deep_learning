#!/bin/bash 
#SBATCH -n 40 
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "train_complex_choose_better_with_under_unit_feature();exit;"