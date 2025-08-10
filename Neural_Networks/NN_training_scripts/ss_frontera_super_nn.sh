#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J acc_cat_pred_with_gr_univ_rank_and_mult_waves
#SBATCH -o super_output.txt 
#SBATCH -e super_output.txt 
#SBATCH -t 48:00:00
module load matlab/2023b
matlab -batch "acc_cat_pred_with_gr_univ_rank_and_mult_waves();exit;"