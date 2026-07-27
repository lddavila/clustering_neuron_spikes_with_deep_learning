#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J nn_train
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
module load matlab/2023b
matlab -batch "train_prob_dist_nn_equ_diff_grades_3_w_temp_scaling();exit;"