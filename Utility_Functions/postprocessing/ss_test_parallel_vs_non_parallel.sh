#!/bin/bash 
#SBATCH -n 40 
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e output.txt
module load matlab/R2024b
matlab -batch "test_parallel_vs_non_parallel();exit;"