#!/bin/bash 
#SBATCH -n 40
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "ks4_1200_unit_sim_no_drift_first_300_secs();exit;"