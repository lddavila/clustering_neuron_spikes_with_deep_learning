#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J linspace_testing
#SBATCH -o output.txt 
#SBATCH -e output.txt
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL	
#SBATCH --mail-user=lddavila@miners.utep.edu
module load matlab/2023b
matlab -batch "test_core_clustering_on_hpc();exit;"