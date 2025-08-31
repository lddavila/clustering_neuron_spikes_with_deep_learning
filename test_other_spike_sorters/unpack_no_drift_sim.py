import os
from extract_recordings import extract_recordings 
fp_to_no_drift_sim = os.path.join("scratch","afriedman","clustering_neuron_spikes_with_deep_learning","Data","sim_no_drift")
extract_recordings(fp_to_no_drift_sim)
