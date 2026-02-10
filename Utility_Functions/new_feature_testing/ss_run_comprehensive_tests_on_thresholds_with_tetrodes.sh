#!/bin/bash 
#SBATCH -n 40
#SBATCH -p medium
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "run_comprehensive_tests_on_thresholds_with_tetrodes();exit;"