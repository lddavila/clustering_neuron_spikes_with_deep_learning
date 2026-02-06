#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J rec_5
#SBATCH -o output_2.txt 
#SBATCH -e output_2.txt 
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
module load matlab/2023b
matlab -batch "run_comprehensive_tests_on_thresholds_with_tetrodes();exit;"