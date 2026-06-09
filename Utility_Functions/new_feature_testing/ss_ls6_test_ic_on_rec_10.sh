#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J tst_10
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
#SBATCH -A CCR26037
module load matlab/2023a
matlab -batch "test_ic_on_rec_10(10,true);exit;"