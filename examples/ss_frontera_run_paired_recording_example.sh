#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J paired_rec_10
#SBATCH -o paired_output_10.txt 
#SBATCH -e paired_output_10.txt
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL	
#SBATCH --mail-user=lddavila@miners.utep.edu
module load matlab/2023b
matlab -batch "run_paired_recording_example(10);exit;"