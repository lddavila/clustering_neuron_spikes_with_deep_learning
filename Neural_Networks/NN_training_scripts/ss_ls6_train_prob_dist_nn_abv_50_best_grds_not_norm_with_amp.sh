#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J grds_nnorm_w_amp
#SBATCH -o output_1.txt 
#SBATCH -e output_1.txt 
#SBATCH -t 6:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
#SBATCH -A CCR26037
module load matlab/2023b
matlab -batch "train_prob_dist_nn_abv_50_best_grds_not_norm_with_amp();exit;"