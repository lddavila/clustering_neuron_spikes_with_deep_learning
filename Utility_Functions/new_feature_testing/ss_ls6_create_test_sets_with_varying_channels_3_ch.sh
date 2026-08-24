#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J 3_ch
#SBATCH -o output_3.txt 
#SBATCH -e output_3.txt 
#SBATCH -t 10:00:00
#SBATCH -A CCR26037
module load matlab/2023b
matlab -batch "create_test_sets_with_varying_channels(10,3);exit;"