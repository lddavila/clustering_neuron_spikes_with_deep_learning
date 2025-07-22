#!/bin/bash 
#SBATCH -n 40 
#SBATCH -p gg
#SBATCH -o output.txt 
#SBATCH -e error.txt 
module load matlab/R2024b
matlab -batch "example_10_100; exit;"