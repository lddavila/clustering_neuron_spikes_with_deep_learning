#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J adding_wf
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 10:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
#SBATCH -A CCR26037
module load matlab/2023b
matlab -batch "run_only_the_waveform_stuff_for_bp_tables_on_cluster();exit;"