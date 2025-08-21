#!/bin/bash 
#SBATCH -n 40
#SBATCH -p medium
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -N 1
module load matlab/R2024b
matlab -batch "train_nn_to_predict_acc_cats_with_histograms_only; exit;"