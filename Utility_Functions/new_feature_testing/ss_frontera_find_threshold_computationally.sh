#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -J recording_1
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 48:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lddavila@miners.utep.edu
module load matlab/2023b
matlab -batch "find_threshold_computationally('1_600Neuron300SecondRecordingWithLevel1Noise');exit;"