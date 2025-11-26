from spikeinterface.extractors import toy_example
from run_ks4_using_docker_container import run_various_spike_sorters
import os
from pathlib import Path
import spikeinterface as si
import spikeinterface.extractors as se
import MEArec as mr
import time;
from pathlib import Path
import spikeinterface.sorters.runsorter as _rs

_rs.has_nvidia = lambda: False  # No GPU on this box → make SI skip CUDA paths cleanly
os.system('cls' if os.name == 'nt' else 'clear')
rec = se.MEArecRecordingExtractor(r"C:/Users/ldd77/OneDrive/Desktop/clustering_neuron_spikes_with_deep_learning/Data/0_test10Neuron15SecondRecordingWithLevel1Noise.h5")
print("Finished importing recording")
sorting_true = se.MEArecSortingExtractor(r"C:/Users/ldd77/OneDrive/Desktop/clustering_neuron_spikes_with_deep_learning/Data/0_test10Neuron15SecondRecordingWithLevel1Noise.h5")
print("Finsihed importing ground truth sorting")
save_dir = Path(r"C:/Users/ldd77/OneDrive/Desktop/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/test_docker")



sorting = si.sorters.run_sorter(sorter_name='kilosort4',
    recording=rec,
    remove_existing_folder=True,
    docker_image=True,
    verbose=True)


print(sorting)

cmp_to_gt_results = si.comparison.compare_sorter_to_ground_truth(sorting_true, sorting, exhaustive_gt=True)


print(cmp_to_gt_results)