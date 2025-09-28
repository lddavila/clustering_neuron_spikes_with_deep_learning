from spikeinterface.extractors import toy_example
from run_ks4_using_docker_container import run_various_spike_sorters
import os
from pathlib import Path
import spikeinterface as si
import spikeinterface.extractors as se
import MEArec as mr
import time;

#create a simple recording and ground truth sorting
#toy_example_rec, toy_example_sorting_true = toy_example(duration=30, num_channels=64, num_segments=1, seed=0)


  #  sorting = run_sorter_jobs(
  #      sorter_name="kilosort4",
  #      recording=rec,
  #      docker_image=True,                 # or: "spikeinterface/kilosort4-base:4.0.38_cuda-12.0.0"
  #      installation_mode="pypi",           # ← key change
  #      remove_existing_folder=True,       # ← correct flag
  #      verbose=True,
  #      torch_device="cpu",                # ← run KS4 on CPU (slow)

#get the base directory of this project
#define the base directory of this project
current_script_fp = Path(__file__).absolute()
split_current_fp = current_script_fp.parts
base_index = split_current_fp.index('clustering_neuron_spikes_with_deep_learning')
base_dir = Path(*split_current_fp[:base_index + 1])

#define the directory with the h5 files
data_dir = base_dir / "Data"

# get a list of all the h5 files in the data directory
h5_files = list(data_dir.glob("*.h5"))

#remove the template file if it exists
h5_files = [f for f in h5_files if 'templates_300_neuropixels.h5' not in f.name.lower()]

#print the h5 files found
print(f"Found {len(h5_files)} h5 files: {[f.name for f in h5_files]}")


#define a list of sorters to run
list_of_sorters = ['kilosort4', 'mountainsort5', 'ironclust', 'herdingspikes', 'spyking-circus']


#now import each h5 file as a recording and run the sorters on it
for i, rec_fp in enumerate(h5_files):
    #get the name of the file without the full path
    head, tail = os.path.split(rec_fp)
    tail = tail.replace('.h5', '')
    out_dir  = base_dir / "Default_Results_Dir" / (tail + "_results")
    print(out_dir)
    rec = se.MEArecRecordingExtractor(rec_fp)
    sorting_true = se.MEArecSortingExtractor(rec_fp)
    #add these to the job list
    
    for i in list_of_sorters:
        job_list = []
        job_list.append({'sorter_name': i,
                          'recording': rec, 
                          'installation_mode':"pypi", 
                          'torch_device':"cpu", 
                          'remove_existing_folder':True, 
                          'folder': str(out_dir),
                            'verbose':True,
                            'singularity_image':True
                         })
        start_time = time.time();
        run_various_spike_sorters(sorting_true, job_list,out_dir)
        end_time = time.time();
        print(f"Time taken for {i} on {tail}: {end_time - start_time} seconds") 
        time_taken = end_time - start_time
        with open(out_dir / f"{i}_time.txt", "w") as f:
            f.write(f"Time taken for {i} on {tail}: {time_taken} seconds\n")
            f.close()