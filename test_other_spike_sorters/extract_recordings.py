from mtscomp import compress, decompress
import spikeinterface as si
import spikeinterface.full as si
import os
from get_per_channel_data_from_binary_file import get_per_channel_data_from_binary_file
from get_timestamps_for_recording import get_timestamps_for_recording
from get_gt_from_params_npz_file import get_gt_from_params_npz_file
def extract_recordings(fp_to_ephys_file,sampling_frequency=30000.0,num_channels=385,dtype="int16",gain_to_uV=0.195,offset_to_uV=0,dur=60):
    head, dir_to_save_output = os.path.split(fp_to_ephys_file)
    files = [f for f in os.listdir(fp_to_ephys_file) if os.path.isfile(os.path.join(fp_to_ephys_file, f))]
    
    #decompress if needed
    if 'sim.imec0.ap.bin' not in files and 'sim.imec0.ap.cbin' in files: 
        print("No decompressed file found, decompressing now...")
        arr = decompress(os.path.join(fp_to_ephys_file,'sim.imec0.ap.cbin'), os.path.join(fp_to_ephys_file,'sim.imec0.ap.ch'))
        X = arr[:, :]  # decompress the data on the fly directly from the file on disk
        arr.close()  # Close the file when done
        print("Decompression complete.")

    dir_to_save_output = os.path.join(dir_to_save_output+"_decompressed")
    # create output directories if they don't exist    
    try:
        os.makedirs(dir_to_save_output)
    except OSError as e:
        print(f"Directory {dir_to_save_output} already exists or could not be created: {e}")
    
    recordings_by_channel_dir = os.path.join(dir_to_save_output, "recordings_by_channel")
    try:
        os.makedirs(recordings_by_channel_dir)
    except OSError as e:
        print(f"Directory {dir_to_save_output} already exists or could not be created: {e}")

    recording_ts_dir = os.path.join(dir_to_save_output, "timestamps")
    try:
        os.makedirs(recording_ts_dir)
    except OSError as e:
        print(f"Directory {dir_to_save_output} already exists or could not be created: {e}")

    ground_truth_dir = os.path.join(dir_to_save_output, "ground_truth")
    try:
        os.makedirs(ground_truth_dir)
    except OSError as e:
        print(f"Directory {dir_to_save_output} already exists or could not be created: {e}")
    
    #now create read the decompresed file
    file_path = os.path.join(fp_to_ephys_file,"sim.imec0.ap.bin")
    # Confirm file existence
    print(file_path);
    assert file_path.is_file(), f"Error: {file_path} is not a valid file. Please check the path."

    #read the binary file into a recording object
    recording = si.read_binary(file_paths=file_path, sampling_frequency=sampling_frequency, num_channels=num_channels, dtype=dtype,gain_to_uV=gain_to_uV, offset_to_uV=offset_to_uV)

    get_per_channel_data_from_binary_file(recording,dir_to_save_output,list(range(num_channels)),dur,gain_to_uV,offset_to_uV,sampling_frequency,dtype,num_channels)
    get_timestamps_for_recording(recording,dir_to_save_output)
    fp_to_npz_file = os.path.join(fp_to_ephys_file,"sim.imec0.ap_params.npz");
    get_gt_from_params_npz_file(fp_to_npz_file,dir_to_save_output)
