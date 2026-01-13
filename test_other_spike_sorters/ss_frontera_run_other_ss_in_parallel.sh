#!/bin/bash
#SBATCH -J test_other_ss
#SBATCH -A ASC25063
#SBATCH -p small
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 48:00:00
#SBATCH --array=0-29%10
#SBATCH -o output_%A_%a.txt
#SBATCH -e output_%A_%a.txt

set -eo pipefail

module purge
module load gcc/9.1.0
module load python3/3.9.2

echo "Loaded modules:"
module list

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

echo "Venv python: $(which python)"
ldd "$(which python)" | grep -E 'libpython|not found' || true

# If you can, preinstall these once and REMOVE this block.
python -m pip install -U pip wheel setuptools
export PIP_ONLY_BINARY=":all:"
python -m pip install "numpy==1.24.4" "pandas==1.5.3"

# Avoid oversubscription
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

python -V
python -c "import numpy, pandas; print('numpy', numpy.__version__, 'pandas', pandas.__version__)"

# -----------------------------
# Map array task -> (recording, sorter)
# -----------------------------
TASK_ID="${SLURM_ARRAY_TASK_ID}"

REC_IDX=$(( TASK_ID / 3 ))
SORT_IDX=$(( TASK_ID % 3 ))

SORTERS=(kilosort4 mountainsort4 ironclust)
SORTER="${SORTERS[$SORT_IDX]}"

DATA_DIR="/scratch2/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Data"

# Build stable list of files (sorted) and exclude template
mapfile -t FILES < <(ls -1 "${DATA_DIR}"/*.h5 | sort | grep -vi "templates_300_neuropixels")

NUM_FILES="${#FILES[@]}"
if (( REC_IDX >= NUM_FILES )); then
  echo "ERROR: REC_IDX=${REC_IDX} but only NUM_FILES=${NUM_FILES} .h5 files found."
  exit 2
fi

REC_FP="${FILES[$REC_IDX]}"

echo "TASK_ID=${TASK_ID} REC_IDX=${REC_IDX}
