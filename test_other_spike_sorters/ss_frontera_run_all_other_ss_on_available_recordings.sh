#!/bin/bash
#SBATCH -J reading
#SBATCH -A ASC25063
#SBATCH -p normal
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 04:00:00
#SBATCH -o output.txt
#SBATCH -e output.txt

set -eo pipefail

module purge
module load gcc/9.1.0
module load python3/3.9.2
module load tacc-apptainer

# Provide 'singularity' shim for SpikeInterface
mkdir -p "$WORK/bin"
cat > "$WORK/bin/singularity" <<'EOF'
#!/usr/bin/env bash
exec apptainer "$@"
EOF
chmod +x "$WORK/bin/singularity"
export PATH="$WORK/bin:$PATH"

# Put Apptainer caches on scratch, not $HOME
export APPTAINER_CACHEDIR="$SCRATCH/apptainer_cache"
export APPTAINER_TMPDIR="$SCRATCH/apptainer_tmp"
mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"

# Activate your venv (adjust path if needed)
source $WORK/ss_env39/bin/activate

# Avoid over-subscription by BLAS
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1

echo "Python path: $(which python)"
python -V
pip show MEArec || true

# IMPORTANT: use $SCRATCH (not /scratch) inside your scripts/paths
python /scratch1/10595/lddavila/clustering_neuron_spikes_with_deep_learning/test_other_spike_sorters/run_all_other_ss_on_available_recordings.py
