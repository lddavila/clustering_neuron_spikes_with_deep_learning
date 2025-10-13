#!/bin/bash 
#SBATCH -N 2
#SBATCH -p medium
#SBATCH -J var_noise_lvs
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 1:00:00
module load matlab/2023b
matlab -batch "run_examples_of_varying_noise_level();exit;"