#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J 6_ch
#SBATCH -o output_6.txt 
#SBATCH -e output_6.txt 
#SBATCH -t 48:00:00
#SBATCH -A CCR26037
module load matlab/2023b
matlab -batch "run_full_pass(10,6,10);exit;"