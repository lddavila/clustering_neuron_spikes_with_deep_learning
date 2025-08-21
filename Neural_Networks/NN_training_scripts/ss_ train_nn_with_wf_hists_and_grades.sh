#!/bin/bash 
#SBATCH -n 40
#SBATCH -p medium
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -N 1
module load matlab/R2024b
matlab -batch " train_nn_with_wf_hists_and_grades; exit;"