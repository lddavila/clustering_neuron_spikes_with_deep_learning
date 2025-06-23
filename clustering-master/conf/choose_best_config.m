function config = choose_best_config()
%choose_best_config will return a config file that will be used by
%return_best_config_of_cluster.m 

config = struct();

% Prints extra output
config.DEBUG = false;



config.MAX_EUC_DIST = 50; %serves as an upper bound of euclidean distance between cluster template wave forms to check when merging clusters 
config.UPDATE_CLASSIFICATION = false; %when true every grade will be updated with the latest classification using classify_clusters_based_on_grades_ver_3
config.OVERLAP = 80; %the minimum percentage that clusters must overlap to be counted as the same cluster
config.ONLY_OVERLAP_WITH_NEURONS =true; %when this is used return_best_config_of_cluster will only allow overlaps if the overlapping cluster is also a neuron 
config.ONLY_NEURONS = false; %when set to true updated_table_of_other_appearences will only include neurons, when set to false it will also include clusters listed as MUA
config.UPDATE_GRADES = true;
config.NUM_OF_UNITS = 100; %this tells you how many units are in the recording, it must be set if SIMULATED = true;
config.SIMULATED = true; %when set to true, it indicates that your data is simulated and thus you MUST indicate the number of units
config.ART_TETR_ARRAY = build_artificial_tetrode; %this is an array which tells you how to configure your channels, this should be changed when using a new probe with different channel numbers
                                                  %each row should correspond a grouping of channels you want to create

                                            

config.TIME_DELTA = 0.004;
config.IS_IDEAL_DIMS_PASS = true;

config.MIN_IMPROV_THRESH = 0.1;
config.SCALE_FACTOR = -1;


config.NUM_DPTS_TO_SLICE = 60;

config.NUM_OF_STD_ABOVE_MEAN = 20;

config.NUM_DIMS_TO_USE_FOR_RECLUSTERING = 3;
config.DIR_TO_SAVE_RECLUSTERING_TO ="D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise Refinement Pass " + string(config.NUM_DIMS_TO_USE_FOR_RECLUSTERING) +" Channels";
config.SAVE_DIRECTORY = 'D:\cluster_neuronspikes\Data'; %where any important data will be saved to
config.BLIND_PASS_DIR_PRECOMPUTED = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise"; %the parent directory where the blind pass precomputed info is saved (things like spikes per channel and std per channel) 
config.TIMESTAMP_FP = "D:\spike_gen_data\Recordings By Channel Timestamps\0_100Neuron300SecondRecordingWithLevel3Noise\timestamps.mat";
config.DIR_WITH_OG_CHANNEL_RECORDINGS = "D:\spike_gen_data\Recordings By Channel\0_100Neuron300SecondRecordingWithLevel3Noise";
config.DIR_WITH_CHANNEL_WISE_MEANS_AND_STDS = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\mean_and_std\mean_and_std.mat";
config.GENERIC_GRADES_DIR = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\initial_pass min z_score"; % a generic file path which can be modified to access grades of various cluster configurations
config.GENRIC_DIR_WITH_OUTPUTS = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\initial_pass_results min z_score"; %a generic file path which can be modified to access the results of clustering
config.DIR_TO_SAVE_RECLUSTERING_TO ="D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise Refinement Pass " + string(config.NUM_DIMS_TO_USE_FOR_RECLUSTERING) +" Channels";
config.GT_FP = "D:\spike_gen_data\Recording By Channel Ground Truth\0_100Neuron300SecondRecordingWithLevel3Noise.h5.mat";

config.ON_HPC = true;
config.NUM_DIMS_TO_USE_FOR_RECLUSTERING_ON_HPC = [2 3 4 5 6 7];
config.DIR_TO_SAVE_RECLUSTERING_TO_ON_HPC =fullfile("/home","lddavila","Reclusted Passs 0_100_3","Refinement Pass " + string(config.NUM_DIMS_TO_USE_FOR_RECLUSTERING_ON_HPC) +" Channels");
config.BLIND_PASS_DIR_PRECOMPUTED_ON_HPC = fullfile("/home","lddavila","spike_gen_data","0_100Neuron300SecondRecordingWithLevel3Noise"); %the parent directory where the blind pass precomputed info is saved (things like spikes per channel and std per channel) 
config.TIMESTAMP_FP_ON_HPC = fullfile("/home","lddavila","timestamps","Recordings By Channel Timestamps","0_100Neuron300SecondRecordingWithLevel3Noise","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS_ON_HPC = fullfile("/home","lddavila","spike_gen_data","0_100Neuron300SecondRecordingWithLevel3Noise_og_recordings");
config.DIR_WITH_CHANNEL_WISE_MEANS_AND_STDS_ON_HPC = fullfile("/home","lddavila","spike_gen_data","0_100Neuron300SecondRecordingWithLevel3Noise","mean_and_std","mean_and_std.mat");
config.GENERIC_GRADES_DIR_ON_HPC = fullfile("/home","lddavila","spike_gen_data","0_100Neuron300SecondRecordingWithLevel3Noise","initial_pass min z_score"); % a generic file path which can be modified to access grades of various cluster configurations
config.GENRIC_DIR_WITH_OUTPUTS_ON_HPC = fullfile("/home","lddavila","spike_gen_data","0_100Neuron300SecondRecordingWithLevel3Noise","initial_pass_results min z_score"); %a generic file path which can be modified to access the results of clustering
config.FP_TO_GT_FOR_RECORDING_ON_HPC = fullfile("/home","lddavila","ground_truth","Recording By Channel Ground Truth","0_100Neuron300SecondRecordingWithLevel3Noise.h5.mat");
config.FP_TO_TABLE_OF_BEST_CHANNELS = fullfile("/home","lddavila","data_from_local_server",'table_with_best_channels based on amplitude.mat');
config.MIN_UNIT_APPEARENCE_THRESHOLD = 30;

config.NAMES_OF_CURR_GRADES =["lratio","cv","short isi","incompleteness compare wire","mahal/isolation distance compare wire",...
    "# of spikes","stationary","Temp Matching With Rep Wire","Min Bhat Dist","Bhat Distance To Unsorted","Lratio from noise",...
    "cv with 0.5","cv with 0.33", "cv with 0.24",...
    "# of isi < 7.5ms / # isi < 100ms","snr 0.5 compare wire","snr 0.33 compare wire","snr 0.24 compare wire",...
    "bhat dist to near threshold spikes","bhat dist to near cluster peaks",...
    "# of intersection between cluster and nearest cluster","cluster duration /length of entire config",...
    "cluster mpc","# of singular cols", "avg spike duration","# of timestamps / duration of conifg", ...
    "has valley","compare wire skewness","cluster template matching","symmetry of the cluster's histogram",...
    "Cluster Amp Cat","Cluster Compare Wire Amp Category","likelihood of multi unit acticity","bhat dist to possibly mua clusters","Tightness of waveform based on euc dist",...
    "Compare Wire tightness of waveform based on euc dist","do not use","do not use","Under/overpowered","Mean SNR",...
    "likeliness of burst","compare wire","2nd compare wire","avg compare wire cluster z score","SNR by dimensions","SNR based on 2 Compare Wires", "Mean Spike Amplitude Per Channel","Mean Z Score Per Channel Cluster Only","Channels",...
    "Mean Z Score Per Channel all spikes in config","compare wire Mean z score Cluster Only","Compare Mean Z Score All Spikes In Config","Compare Wire Mean Amp"];  
end
