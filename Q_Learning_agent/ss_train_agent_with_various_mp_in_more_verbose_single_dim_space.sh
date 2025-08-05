#!/bin/bash 
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J q_learning_agent
#SBATCH -o output.txt 
#SBATCH -e output.txt 
#SBATCH -t 4:00:00
module load matlab/2023b
matlab -batch "train_agent_with_various_mp_in_more_verbose_single_dim_space();exit;"