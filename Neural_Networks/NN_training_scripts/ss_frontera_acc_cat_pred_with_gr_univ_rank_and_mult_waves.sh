#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J q_learning_agent
#SBATCH -o verbose_wf_output.txt 
#SBATCH -e verbose_wf_error.txt 
#SBATCH -t 4:00:00
module load matlab/2023b
matlab -batch "acc_cat_pred_with_gr_univ_rank_and_mult_waves();exit;"