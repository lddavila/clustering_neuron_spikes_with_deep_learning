#!/bin/bash 
#SBATCH -n 10
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "ks4_1200_unit_sim_no_drift();exit;"