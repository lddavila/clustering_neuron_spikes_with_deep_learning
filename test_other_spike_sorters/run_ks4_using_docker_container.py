
import shutil
from spikeinterface.extractors import toy_example
from spikeinterface import create_sorting_analyzer
#from spikeinterface import compare_sorter_to_ground_truth
from spikeinterface.sorters import run_sorter_jobs
import spikeinterface.sorters.runsorter as _rs
import spikeinterface as si
import os
from spikeinterface.comparison import compare_sorter_to_ground_truth
import numpy as np
import spikeinterface.comparison as sc
import pandas as pd

def run_various_spike_sorters(sorting_true,job_list_current,out_dir):
    _rs.has_nvidia = lambda: False  # No GPU on this box → make SI skip CUDA paths cleanly
    os.system('cls' if os.name == 'nt' else 'clear')

    # start fresh instead of using "overwrite" on run_sorter
    #shutil.rmtree(out_dir, ignore_errors=True)
    #out_dir.mkdir(parents=True, exist_ok=True)

    #sorting = si.sorters.run_sorter(sorter_name='kilosort4',
    #recording=rec,
    #remove_existing_folder=True,
    #docker_image=True,
    #verbose=True)")

    #check to see if the sorter already exists, and if it does then load it instead of running it again
    if os.path.exists(out_dir / 'sorting'):
        print(f"Sorter {job_list_current['sorter_name']} already exists, loading it from {out_dir / 'sorting'}")
        sorting = si.load_extractor(out_dir / 'sorting')
    else:
        sorting = si.sorters.run_sorter(job_list_current['sorter_name'],
            recording=job_list_current['recording'],
            remove_existing_folder=job_list_current['remove_existing_folder'],
            singularity_image=job_list_current['singularity_image'],
            verbose=job_list_current['verbose'])
    print("Finished sorting for "+job_list_current['sorter_name'])
    print(sorting)

    #now save the sorting
    sorting.save(folder=str(out_dir / 'sorting'), overwrite=True)



    #now compare the sorter to the ground truth
    cmp_to_gt_results =sc.compare_sorter_to_ground_truth(sorting_true, sorting, exhaustive_gt=True,delta_time=0.2)

    #now save the agreement matrix to the output folder to get accuracy results
     
     #      job_dict = {'sorter_name': i,
     #                     'recording': rec, 
     #                     'installation_mode':"pypi", 
     #                     'torch_device':"cpu", 
     #                     'remove_existing_folder':True, 
     #                     'folder': str(out_dir),
     #                       'verbose':True,
     #                       'singularity_image':True
     #                    };
    df = pd.DataFrame(cmp_to_gt_results.agreement_scores).T
    df.to_csv(out_dir / 'agreement_scores.csv')
