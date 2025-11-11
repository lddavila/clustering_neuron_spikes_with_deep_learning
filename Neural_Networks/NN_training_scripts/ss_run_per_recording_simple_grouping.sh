#!/bin/bash 
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -p medium
#SBATCH -J group
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "run_per_recording_simple_grouping();exit;"