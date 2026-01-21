#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J examples
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
module load matlab/2023b
matlab -batch "test_spike_windows_perf_with_new_method();exit;"