#!/bin/bash 
#SBATCH -N 1
#SBATCH -p flex**
#SBATCH -J q_learning_agent
#SBATCH -o output.txt 
#SBATCH -e error.txt 
#SBATCH -t 48:00:00
module load matlab/R2023b
matlab -batch "train_agent_with_various_mp_in_more_verbose_single_dim_space();exit;"