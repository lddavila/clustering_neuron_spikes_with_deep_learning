#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J jg_param_sweep
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
#SBATCH -A CCR26037
module load matlab/2023a
matlab -batch "run_multilevel_grade_combo_search();exit;"