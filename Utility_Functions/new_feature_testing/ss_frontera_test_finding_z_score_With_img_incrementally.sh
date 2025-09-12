#!/bin/bash 
#SBATCH -N 2
#SBATCH -p normal
#SBATCH -J training
#SBATCH -o output.txt
#SBATCH -e output.txt
#SBATCH -t 48:00:00
module load matlab/2023b
matlab -batch "test_finding_z_score_With_img_incrementally();exit;"