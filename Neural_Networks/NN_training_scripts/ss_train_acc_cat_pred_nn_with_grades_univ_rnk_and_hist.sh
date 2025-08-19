#!/bin/bash 
#SBATCH -n 40 
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "train_acc_cat_pred_nn_with_grades_univ_rnk_and_hist();exit;"