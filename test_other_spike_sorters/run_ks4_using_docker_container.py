
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
import numpy as np


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
    
    sorting = si.sorters.run_sorter(job_list_current['sorter_name'],
        recording=job_list_current['recording'],
        remove_existing_folder=job_list_current['remove_existing_folder'],
        singularity_image=job_list_current['singularity_image'],
        verbose=job_list_current['verbose'])
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
    np.savetxt(out_dir / job_list_current['sorter_name']+'_agreement_matrix.csv', cmp_to_gt_results.agreement_matrix, delimiter=',')
