#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J det_sp
#SBATCH -o output.txt 
#SBATCH -e output.txt
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL	
#SBATCH --mail-user=lddavila@miners.utep.edu
module load matlab/2023b
matlab -batch "get_detected_spikes_for_every_channel(10);exit;"