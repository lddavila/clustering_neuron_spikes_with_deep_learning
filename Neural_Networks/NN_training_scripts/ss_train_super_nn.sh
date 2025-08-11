#!/bin/bash 
#SBATCH -n 37
#SBATCH -p medium
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -N 1
module load matlab/R2024b
matlab -batch "train_super_nn; exit;"