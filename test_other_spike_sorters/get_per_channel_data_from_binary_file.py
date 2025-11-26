from scipy.io import savemat
import os
def get_per_channel_data_from_binary_file(recording,dir_to_save_output,list_of_channels,dur):
    print("Getting per channel data from binary file")
    sf = recording.get_sampling_frequency()
    dur = recording.get_duration()
    t0   = 0.0        # start time (s)
    start = int(t0 * sf)
    end   = start + int(dur * sf)
    for i in list_of_channels:
        channel_data = recording.get_traces(start_frame=start,
        end_frame=end,
        channel_ids=[i],
        return_in_uV=True,).squeeze();
        mat_dict = {f"c_{i+1}": channel_data}
        savemat(os.path.join(dir_to_save_output,"recordings_by_channel",f"c{i+1}.mat"), mat_dict)
        print("Finished channel ",i+1, " out of ",len(list_of_channels))