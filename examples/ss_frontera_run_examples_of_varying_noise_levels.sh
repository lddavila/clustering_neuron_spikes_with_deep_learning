#!/bin/bash
#SBATCH -J var_noise_lvs
#SBATCH -p normal
#SBATCH -N 3
#SBATCH --ntasks-per-node=52         # 3 × 52 = 156 workers (headroom on each node)
#SBATCH -t 48:00:00
#SBATCH -o output.%j.txt
#SBATCH -e error.%j.txt

module purge
module load matlab/2023b

# keep workers single-threaded
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

# shared job store visible to all nodes
export JOBSTORE="/scratch1/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir"

matlab -batch "run_examples_of_varying_noise_level(); exit"