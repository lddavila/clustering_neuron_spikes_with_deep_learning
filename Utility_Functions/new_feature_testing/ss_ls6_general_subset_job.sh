#!/bin/bash
#SBATCH -N 1
#SBATCH -p normal
#SBATCH -J varying_channels
#SBATCH -o output_%x_%j.txt
#SBATCH -e output_%x_%j.txt
#SBATCH -t 1:00:00
#SBATCH -A CCR26037

set -euo pipefail

channels=""
recordings=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -ch|--channels)
            channels="$2"
            shift 2
            ;;
        -rec|--recordings)
            recordings="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: sbatch $0 -ch CHANNELS -rec RECORDINGS"
            exit 1
            ;;
    esac
done

if [[ ! "$channels" =~ ^[0-9]+$ ]] || [[ ! "$recordings" =~ ^[0-9]+$ ]]; then
    echo "Error: -ch and -rec must both be positive integers."
    echo "Usage: sbatch $0 -ch CHANNELS -rec RECORDINGS"
    exit 1
fi

module load matlab/2023b

echo "Running with recordings=$recordings and channels=$channels"

matlab -batch "create_test_sets_with_varying_channels(${recordings},${channels})"