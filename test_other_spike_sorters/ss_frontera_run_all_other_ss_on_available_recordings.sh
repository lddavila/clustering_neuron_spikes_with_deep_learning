#!/bin/bash
#SBATCH -J test_other_ss
#SBATCH -A ASC25063
#SBATCH -p normal
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 01:00:00
#SBATCH -o output.txt
#SBATCH -e output.txt

set -euo pipefail

module purge

# Python 3.9 on Frontera needs a newer GCC first
module load gcc/9.1.0

# Some queues/nodes expose python3/3.9.2, others python/3.9.2 — try both.
(module load python3/3.9.2) || (module load python/3.9.2)

module load tacc-apptainer

# --- "singularity" shim for SpikeInterface ---
mkdir -p "$WORK/bin"
cat > "$WORK/bin/singularity" <<'EOF'
#!/usr/bin/env bash
exec apptainer "$@"
EOF
chmod +x "$WORK/bin/singularity"
export PATH="$WORK/bin:$PATH"

# --- Apptainer caches on scratch ---
export APPTAINER_CACHEDIR="$SCRATCH/apptainer_cache"
export APPTAINER_TMPDIR="$SCRATCH/apptainer_tmp"
mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"

# --- Activate venv ---
source "$WORK/ss_env39/bin/activate"

# --- Wheel-only installs to avoid compiling on the node ---
python -m pip install -U pip wheel setuptools
export PIP_ONLY_BINARY=":all:"
python -m pip install "numpy==1.24.4" "pandas==1.5.3"

# --- Avoid BLAS oversubscription ---
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1

echo "Python: $(which python)"
python -V
python -c "import numpy, pandas; print('numpy', numpy.__version__, 'pandas', pandas.__version__)"

python /scratch1/10595/lddavila/clustering_neuron_spikes_with_deep_learning/test_other_spike_sorters/run_all_other_ss_on_available_recordings.py
