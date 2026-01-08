#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J acc_cat_pred_with_gr_univ_rank_and_mult_waves
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
module load matlab/R2024b
matlab -batch "train_prob_dist_nn_equalize_difficulty_grades_3();exit;"