#!/bin/bash 
#SBATCH -n 40
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "test_finding_z_score_With_img_incrementally();exit;"