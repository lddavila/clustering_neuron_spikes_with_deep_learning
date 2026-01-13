from run_ks4_using_docker_container import run_various_spike_sorters
import os
from pathlib import Path
import spikeinterface.extractors as se
import time
import argparse

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--one-file", type=str, default=None,
                   help="Path to a single .h5 file (absolute preferred). If relative, assumed under Data/.")
    p.add_argument("--one-sorter", type=str, default=None,
                   help="Run only one sorter (kilosort4|mountainsort4|ironclust).")
    return p.parse_args()

args = parse_args()

# Base directory of project
current_script_fp = Path(__file__).absolute()
split_current_fp = current_script_fp.parts
base_index = split_current_fp.index('clustering_neuron_spikes_with_deep_learning')
base_dir = Path(*split_current_fp[:base_index + 1])

data_dir = base_dir / "Data"

# Build file list
if args.one_file:
    rec_fp = Path(args.one_file)
    if not rec_fp.is_absolute():
        rec_fp = data_dir / rec_fp
    h5_files = [rec_fp]
else:
    h5_files = sorted(data_dir.glob("*.h5"))
    h5_files = [f for f in h5_files if 'templates_300_neuropixels.h5' not in f.name.lower()]

print(f"Found {len(h5_files)} h5 files: {[f.name for f in h5_files]}")

# Sorter list
default_sorters = ['kilosort4', 'mountainsort4', 'ironclust']
if args.one_sorter:
    if args.one_sorter not in default_sorters:
        raise ValueError(f"--one-sorter must be one of {default_sorters}, got {args.one_sorter}")
    list_of_sorters = [args.one_sorter]
else:
    list_of_sorters = default_sorters

for rec_fp in h5_files:
    tail = rec_fp.stem  # filename without .h5

    rec = se.MEArecRecordingExtractor(rec_fp)
    sorting_true = se.MEArecSortingExtractor(rec_fp)

    print("About to run sorters on " + tail)

    for sorter_name in list_of_sorters:
        out_dir = base_dir / "Default_Results_Dir" / f"{tail}_results_{sorter_name}"
        out_dir.mkdir(parents=True, exist_ok=True)

        job_dict = {
            'sorter_name': sorter_name,
            'recording': rec,
            'installation_mode': "pypi",
            'torch_device': "cpu",
            'remove_existing_folder': True,
            'folder': str(out_dir),
            'verbose': True,
            'singularity_image': True
        }

        start_time = time.time()
        already_done = (out_dir / 'sorting').exists()

        run_various_spike_sorters(sorting_true, job_dict, out_dir)

        end_time = time.time()
        time_taken = end_time - start_time
        print(f"Time taken for {sorter_name} on {tail}: {time_taken} seconds")

        if not already_done:
            with open(out_dir / f"{sorter_name}_time.txt", "w") as f:
                f.write(f"Time taken for {sorter_name} on {tail}: {time_taken} seconds\n")
