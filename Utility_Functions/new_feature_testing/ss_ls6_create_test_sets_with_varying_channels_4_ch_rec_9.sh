#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J 4_ch_sub_rec_9
#SBATCH -o output_4_sub_rec_9.txt 
#SBATCH -e output_4_sub_rec_9.txt 
#SBATCH -t 1:00:00
#SBATCH -A CCR26037
module load matlab/2023b
matlab -batch "create_test_sets_with_varying_channels(9,4);exit;"