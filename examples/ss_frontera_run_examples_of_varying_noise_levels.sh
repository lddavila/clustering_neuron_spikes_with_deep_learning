#!/bin/bash 
#SBATCH -N 3
#SBATCH -n 168
#SBATCH -p normal
#SBATCH -J var_noise_lvs
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
module load matlab/2023b
matlab -batch "run_examples_of_varying_noise_level();exit;"