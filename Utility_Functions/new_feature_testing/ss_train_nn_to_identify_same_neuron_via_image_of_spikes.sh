#!/bin/bash 
#SBATCH -n 40
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch "train_nn_to_identify_same_neuron_via_image_of_spikes();exit;"