#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J st_tm_tst
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
module load matlab/2023b
matlab -batch "test_parallel_start_process_time();exit;"