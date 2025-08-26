#!/bin/bash 
#SBATCH -n 40 
#SBATCH -p medium 
#SBATCH -o output.txt 
#SBATCH -e output.txt 

URL="https://janelia.figshare.com/ndownloader/articles/25298815/versions/1"
OUT="Kilosort4_simulations.zip"

wget -c --show-progress -O "$OUT" "$URL"
