#!/bin/bash 
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -p medium
#SBATCH -J group
#SBATCH -o output.txt 
#SBATCH -e output.txt 
module load matlab/R2024b
matlab -batch 'transfer_minimal_files("/scratch/cnheaton/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir","/G/david_spikesorting_paper_data/OneDrive - The University of Texas at El Paso/Cluster Images Sorted into 5 accuracy categories/data_to_reference_for_figures");exit;'