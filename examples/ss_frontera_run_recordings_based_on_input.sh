#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J rec_6_ic
#SBATCH -o output_6.txt 
#SBATCH -e output_6.txt
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
module load matlab/2023b
matlab -batch "run_recordings_based_on_input(6);exit;"