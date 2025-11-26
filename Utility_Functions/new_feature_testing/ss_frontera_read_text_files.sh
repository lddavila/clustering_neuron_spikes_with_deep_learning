#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J reading
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 1:00:00
module load matlab/2023b
matlab -batch "read_text_files();exit;"