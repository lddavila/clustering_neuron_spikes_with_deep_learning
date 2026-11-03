#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J grds_w_amp
#SBATCH -o output_2.txt 
#SBATCH -e output_2.txt 
#SBATCH -t 6:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
#SBATCH -A CCR26037
module load matlab/2023b
matlab -batch "train_prob_dist_nn_abc_50_equ_diff_grades_best_grds_wth_amp();exit;"