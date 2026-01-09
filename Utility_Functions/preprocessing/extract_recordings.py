import MEArec as mr
import numpy as np
import matplotlib.pylab as plt
import spikeinterface.extractors as se
import spikeinterface.sorters as ss
import spikeinterface.widgets as sw
import spikeinterface.comparison as sc
import numpy as np
import pandas as pd 
import matplotlib.pyplot as plt
import spikeinterface.full as si
from scipy.io import savemat
import os
def extract_recordings(recording_fp,dir_to_save_output):

    try:
        os.makedirs(dir_to_save_output)
    except OSError as e:
        print(f"Directory {dir_to_save_output} already exists or could not be created: {e}")

    try:
        os.makedirs(os.path.join(dir_to_save_output,"recordings_by_channel"))
    except OSError as e:
        print(f"Directory {dir_to_save_output} already exists or could not be created: {e}")

    try:
        os.makedirs(os.path.join(dir_to_save_output,"timestamps"))
    except OSError as e:
        print(f"Directory {dir_to_save_output} already exists or could not be created: {e}")

    try:
        os.makedirs(os.path.join(dir_to_save_output,"ground_truth"))
    except OSError as e:
        print(f"Directory {dir_to_save_output} already exists or could not be created: {e}")
    
    rec = se.MEArecRecordingExtractor(recording_fp)
    print("Finished loading recording for "+ recording_fp)

    channel_ids = rec.get_channel_ids()
    print("Finished getting channel ids for "+ recording_fp)

    print(channel_ids)
    for i in channel_ids:
        channel_data = rec.get_traces(channel_ids=[i])
        mat_dict = {f"c_{i}": channel_data}
        savemat(os.path.join(dir_to_save_output,"recordings_by_channel",f"c{i}.mat"), mat_dict)
        print(f"Saved channel {i} data to {os.path.join(dir_to_save_output,'recordings_by_channel',f'channel_{i}.mat')}")

    timestamps = rec.get_times()
    savemat(os.path.join(dir_to_save_output,"timestamps","timestamps.mat"), {"timestamps": timestamps})
    print(f"Saved timestamps to {os.path.join(dir_to_save_output,'timestamps','timestamps.mat')}")

    sorting = se.MEArecSortingExtractor(recording_fp)
    print("Finished loading sorting extractor for "+ recording_fp)
    
    ground_truth_unit_ids = sorting.get_unit_ids()
    ground_truth_array = []
    for i in ground_truth_unit_ids:
        ground_truth_array.append(sorting.get_unit_spike_train(i))

    ground_truth_dict = {"spike_trains": ground_truth_array};
    savemat(os.path.join(dir_to_save_output,"ground_truth","ground_truth.mat"), ground_truth_dict)
    print(f"Saved ground truth to {os.path.join(dir_to_save_output,'ground_truth','ground_truth.mat')}")

