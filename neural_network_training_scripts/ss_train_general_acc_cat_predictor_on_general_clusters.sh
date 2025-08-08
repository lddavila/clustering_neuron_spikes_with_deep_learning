#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J gen_acc
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 4:00:00
module load matlab/2023b
matlab -batch "train_general_acc_cat_predictor_on_general_clusters();exit;"