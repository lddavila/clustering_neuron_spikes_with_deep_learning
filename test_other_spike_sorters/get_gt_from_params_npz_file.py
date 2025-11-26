from scipy.io import savemat
import os
import numpy as np
def get_gt_from_params_npz_file(name_of_file,dir_to_save_output):
    d = np.load(name_of_file)
    st = d["st"]          # samples
    cl = d["cl"]          # unit ids
    unique_gt_ids = np.unique(cl)
    ground_truth_array = [];
    for i in unique_gt_ids:
        ground_truth_array.append(st[cl==i])
    print("Finished getting gt")
    ground_truth_dict = {"spike_trains": ground_truth_array};
    savemat(os.path.join(dir_to_save_output,"ground_truth","ground_truth.mat"), ground_truth_dict)