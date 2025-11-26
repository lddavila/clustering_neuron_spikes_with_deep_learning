from scipy.io import savemat
import os
def get_timestamps_for_recording(recording,dir_to_save_output):
    timestamps = recording.get_times()
    savemat(os.path.join(dir_to_save_output,"timestamps","timestamps.mat"), {"timestamps": timestamps})