#!/bin/bash 
#SBATCH -n 144
#SBATCH -p gg
#SBATCH -t 15:00:00
#SBATCH -o output.txt 
#SBATCH -e error.txt 
#SBATCH -N 1
module load matlab/R2023b
matlab -batch "example_10_100; exit;"