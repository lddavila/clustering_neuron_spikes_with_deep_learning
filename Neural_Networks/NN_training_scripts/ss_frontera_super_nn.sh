#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J train_super_nn
#SBATCH -o super_output.txt 
#SBATCH -e super_output.txt 
#SBATCH -t 48:00:00
module load matlab/2023b
matlab -batch "train_super_nn();exit;"