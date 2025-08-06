#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J verbose_waveforms
#SBATCH -o verbose_waveforms.txt 
#SBATCH -e verbose_waveforms.txt 
#SBATCH -t 4:00:00
module load matlab/2023b
matlab -batch "train_mergable_or_not_verbose_waveforms();exit;"