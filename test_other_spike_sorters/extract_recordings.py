from mtscomp import compress, decompress
import spikeinterface as si
import spikeinterface.full as si
import os
import numpy as np
from get_per_channel_data_from_binary_file import get_per_channel_data_from_binary_file
from get_timestamps_for_recording import get_timestamps_for_recording
from get_gt_from_params_npz_file import get_gt_from_params_npz_file
def extract_recordings(fp_to_ephys_file,sampling_frequency=30000.0,num_channels=385,dtype="int16",gain_to_uV=0.195,offset_to_uV=0,dur=60):
    head, dir_to_save_output = os.path.split(fp_to_ephys_file)
    files = [f for f in os.listdir(fp_to_ephys_file) if os.path.isfile(os.path.join(fp_to_ephys_file, f))]
    
    # decompress to a .bin on disk if needed
    if 'sim.imec0.ap.bin' not in files and 'sim.imec0.ap.cbin' in files:
        print("No decompressed file found, decompressing now...")
        cbin_path = os.path.join(fp_to_ephys_file, 'sim.imec0.ap.cbin')
        ch_path = os.path.join(fp_to_ephys_file, 'sim.imec0.ap.ch')
        out_bin_path = os.path.join(fp_to_ephys_file, 'sim.imec0.ap.bin')
        # Create on-the-fly decompressor; this does not write to disk by itself
        arr = decompress(cbin_path, ch_path)
        # Write decompressed data to .bin in chunks to avoid high memory usage
        n_samples, n_channels = arr.shape
        dtype_np = np.int16  # mtscomp for .ap data is int16
        chunk = 1_000_000  # samples per chunk
        print(f"Decompressing to {out_bin_path} | shape=({n_samples},{n_channels}), dtype={dtype_np}")
        mm = np.memmap(out_bin_path, dtype=dtype_np, mode='w+', shape=(n_samples, n_channels))
        try:
            for start in range(0, n_samples, chunk):
                end = min(start + chunk, n_samples)
                mm[start:end, :] = arr[start:end, :].astype(dtype_np, copy=False)
            mm.flush()
            print("Decompression complete: wrote sim.imec0.ap.bin")
        finally:
            # Ensure resources are freed even if something goes wrong
            del mm
            arr.close()

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
    #print(file_path)
    assert os.path.isfile(file_path), f"Error: {file_path} is not a valid file. Please check the path."

    #read the binary file into a recording object
    recording = si.read_binary(file_paths=file_path, sampling_frequency=sampling_frequency, num_channels=num_channels, dtype=dtype,gain_to_uV=gain_to_uV, offset_to_uV=offset_to_uV)

    get_per_channel_data_from_binary_file(recording,dir_to_save_output,list(range(num_channels)),dur)
    get_timestamps_for_recording(recording,dir_to_save_output)
    fp_to_npz_file = os.path.join(fp_to_ephys_file,"sim.imec0.ap_params.npz");
    get_gt_from_params_npz_file(fp_to_npz_file,dir_to_save_output)
