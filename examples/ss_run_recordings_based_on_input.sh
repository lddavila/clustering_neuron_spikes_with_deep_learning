#!/bin/bash 
#SBATCH -n 56
#SBATCH -p medium
#SBATCH -J rec_10_ic
#SBATCH -o output_10.txt 
#SBATCH -e output_10.txt
module load matlab/R2024b
matlab -batch "run_recordings_based_on_input(10);exit;"