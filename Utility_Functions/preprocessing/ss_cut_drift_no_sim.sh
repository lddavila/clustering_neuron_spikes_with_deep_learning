#!/bin/bash 
#SBATCH -n 15
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "get_first_n_seconds_of_recording('/scratch/afriedman/clustering_neuron_spikes_with_deep_learning/Data/sim_no_drift_decompressed',300,'/scratch/afriedman/clustering_neuron_spikes_with_deep_learning/Data/sim_no_drift_first_300_seconds');exit;"