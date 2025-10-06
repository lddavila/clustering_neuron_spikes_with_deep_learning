#!/bin/bash
#SBATCH -J test_other_ss
#SBATCH -A ASC25063
#SBATCH -p normal
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 01:00:00
#SBATCH -o output.txt
#SBATCH -e output.txt

set -eo pipefail

module purge
module load gcc/9.1.0
(module load python3/3.9.2) || (module load python/3.9.2)

# Make sure libpython is on the runtime path (some nodes need this)
PY3_LIBDIR="$(python3 - <<'PY' 2>/dev/null || true
import sysconfig
print(sysconfig.get_config_var('LIBDIR') or '')
PY
)"
if [ -n "${PY3_LIBDIR:-}" ] && [ -d "$PY3_LIBDIR" ]; then
  export LD_LIBRARY_PATH="$PY3_LIBDIR:${LD_LIBRARY_PATH:-}"
fi

# Optional: show what we loaded
module list 2>&1 || true
echo "PY3_LIBDIR=$PY3_LIBDIR"
echo "LD_LIBRARY_PATH snippet=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | head -n 3)"

# Apptainer (no -u to avoid completion bug)
module load tacc-apptainer

# "singularity" shim for SpikeInterface
mkdir -p "$WORK/bin"
cat > "$WORK/bin/singularity" <<'EOF'
#!/usr/bin/env bash
exec apptainer "$@"
EOF
chmod +x "$WORK/bin/singularity"
export PATH="$WORK/bin:$PATH"

# Put Apptainer caches on scratch
export APPTAINER_CACHEDIR="$SCRATCH/apptainer_cache"
export APPTAINER_TMPDIR="$SCRATCH/apptainer_tmp"
mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"

# Activate venv
source "$WORK/ss_env39/bin/activate"

# Sanity-check that libpython resolves for THIS python
echo "Venv python: $(which python)"
ldd "$(which python)" | grep -E 'libpython|not found' || true

# Wheels only (no compiling on node)
python -m pip install -U pip wheel setuptools
export PIP_ONLY_BINARY=":all:"
python -m pip install "numpy==1.24.4" "pandas==1.5.3"

# Avoid BLAS oversubscription
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1

python -V
python -c "import numpy, pandas; print('numpy', numpy.__version__, 'pandas', pandas.__version__)"

python /scratch1/10595/lddavila/clustering_neuron_spikes_with_deep_learning/test_other_spike_sorters/run_all_other_ss_on_available_recordings.py
