#!/bin/bash 
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -p medium
#SBATCH -J group
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch 'transfer_minimal_files(local_base_dir, remote_base_dir);exit;'