#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J examples
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
module load matlab/R2023b
matlab -batch "run_examples_of_varying_noise_level_with_3_channels();exit;"