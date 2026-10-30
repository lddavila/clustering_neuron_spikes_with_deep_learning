#!/bin/bash
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J subset_job
#SBATCH -o subset_%j.out
#SBATCH -e subset_%j.err
#SBATCH -t 48:00:00
#SBATCH -A CCR26037

# Read command-line arguments.
recording=""
channels=""

usage() {
    echo "Usage: sbatch ss_generic_subset_job -n RECORDING -c CHANNELS" >&2
}

while getopts ":n:c:" opt; do
    case "$opt" in
        n) recording="$OPTARG" ;;
        c) channels="$OPTARG" ;;
        :)
            echo "Error: -$OPTARG requires a value." >&2
            usage
            exit 1
            ;;
        \?)
            echo "Error: unknown option -$OPTARG." >&2
            usage
            exit 1
            ;;
    esac
done

shift "$((OPTIND - 1))"

# Require both inputs to be positive integers.
if [[ ! "$recording" =~ ^[1-9][0-9]*$ ||
      ! "$channels" =~ ^[1-9][0-9]*$ ||
      $# -ne 0 ]]; then
    echo "Error: provide -n and -c as positive integers, with no extra arguments." >&2
    usage
    exit 1
fi

# Preserve the working directory from which sbatch was called.
cd "$SLURM_SUBMIT_DIR" || exit 1

module load matlab/2023b || exit 1

echo "Recording: $recording"
echo "Channels:  $channels"
echo "Job ID:    $SLURM_JOB_ID"

matlab -batch "create_test_sets_with_varying_channels(${recording},${channels});"