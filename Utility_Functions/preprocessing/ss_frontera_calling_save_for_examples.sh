#!/bin/bash 
#SBATCH -N 1
#SBATCH -p small
#SBATCH -o output.txt 
#SBATCH -e output.txt
#SBATCH -t 48:00:000
export TMPDIR=/scratch2/10595/$USER/clustering_neuron_spikes_with_deep_learning/Data
mkdir -p $TMPDIR
source /scratch2/10595/$USER/clustering_neuron_spikes_with_deep_learning/Data/spike_env/bin/activate
echo "Python path: $(which python)"
python -m pip list | grep MEArec
python calling_save_for_examples.py