#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J nn_train
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
module load matlab/2023b
matlab -batch "create_3_and_2_channel_data_sets(10,1,'z');exit;"