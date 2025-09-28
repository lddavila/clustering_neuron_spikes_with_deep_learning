#!/bin/bash 
#SBATCH -N 1
#SBATCH -p medium
#SBATCH -J noise_lvls
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "run_examples_of_varying_noise_level();exit;"