#!/bin/bash 
#SBATCH -n 40 
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e error.txt 
module load matlab/R2025a
matlab -batch "train_accuracy_cat_prediction_nn_with_grades_and_universal_rank();exit;"