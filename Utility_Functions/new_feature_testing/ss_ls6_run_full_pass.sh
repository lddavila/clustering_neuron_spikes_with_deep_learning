#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J 2_ch
#SBATCH -o output_2.txt 
#SBATCH -e output_2.txt 
#SBATCH -t 10:00:00
#SBATCH -A CCR26037
module load matlab/2023b
matlab -batch "run_full_pass(10,2);exit;"