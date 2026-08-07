#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J nn_train
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
module load matlab/2023b
matlab -batch "recluster_by_amplitude();exit;"