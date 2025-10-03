
import shutil
from spikeinterface.extractors import toy_example
from spikeinterface import create_sorting_analyzer
#from spikeinterface import compare_sorter_to_ground_truth
from spikeinterface.sorters import run_sorter_jobs
import spikeinterface.sorters.runsorter as _rs
import spikeinterface as sc
import os
from spikeinterface.comparison import compare_sorter_to_ground_truth
import numpy as np


def run_various_spike_sorters(sorting_true,job_list_current,out_dir):
    _rs.has_nvidia = lambda: False  # No GPU on this box → make SI skip CUDA paths cleanly
    os.system('cls' if os.name == 'nt' else 'clear')

    # start fresh instead of using "overwrite" on run_sorter
    #shutil.rmtree(out_dir, ignore_errors=True)
    #out_dir.mkdir(parents=True, exist_ok=True)

    #for every dictionary in job_list add the folder key
    #for i, job in enumerate(job_list_current):
    #    job['folder'] = str(out_dir / f"{job['sorter_name'+'_output']}")
    
    sortings = run_sorter_jobs(job_list=job_list_current)
    print(sortings)

    #now for every sorting in sortings do a ground truth comparison
    for sorter_name, sorting in sortings.items():

        print(f"Results for {sorter_name}")
        cmp_to_gt_results = compare_sorter_to_ground_truth(sorting_true, sorting, exhaustive_gt=True)
        sorting = sorting.save(folder=str(out_dir / f"{sorter_name}_output" / f"{sorter_name}_sorting"), overwrite=True)
        perf = cmp_to_gt_results.get_performance()
        save_path = out_dir / f"{sorter_name}_performance.npy"
        np.save(save_path, perf)
        print(f"Performance saved to {save_path}")
        print(perf)
