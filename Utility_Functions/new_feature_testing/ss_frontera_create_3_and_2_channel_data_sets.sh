#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J sample_set
#SBATCH -o output_2.txt 
#SBATCH -e output_2.txt 
#SBATCH -t 24:00:00
module load matlab/2023b
matlab -batch "create_3_and_2_channel_data_sets(10,1,'z');exit;"