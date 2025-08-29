from scipy.io import savemat
import os
def get_per_channel_data_from_binary_file(recording,dir_to_save_output,list_of_channels,dur,num_channels):
    list_of_channels = list(range(num_channels))
    #gain_to_uV = 0.195  # normally should be in the parameters file, but here it's hardcoded because it's the closest we could find
    #offset_to_uV = 0   # normally in parameters file 
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
        #print(f"Saved channel {i} data to {os.path.join(dir_to_save_output,'recordings_by_channel',f'channel_{i}.mat')}")