#!/bin/bash 
#SBATCH -n 15
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "test_different_z_score_thresholds();exit;"