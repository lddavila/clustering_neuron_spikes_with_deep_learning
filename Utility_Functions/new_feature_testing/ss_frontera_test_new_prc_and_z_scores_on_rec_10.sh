#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J full_pass
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
#SBATCH -A ASC25063
module load matlab/2023b
matlab -batch "test_new_prc_and_z_scores_on_rec_10(10,1,'z');exit;"
