#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J reading
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 24:00:00
module load matlab/2023b
matlab -batch "run_examples_of_varying_noise_level();exit;"