#!/bin/bash 
#SBATCH -n 40
#SBATCH -p small
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -N 1
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL	
#SBATCH --mail-user=lddavila@miners.utep.edu
module load matlab/R2024b
matlab -batch "run_per_unit_spike_detection_per_unit_on_cluster();exit;"