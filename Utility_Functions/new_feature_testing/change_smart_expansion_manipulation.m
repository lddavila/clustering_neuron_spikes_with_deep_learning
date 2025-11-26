function [] = change_smart_expansion_manipulation()
home_dir = cd("..");
cd("..")
addpath(genpath(pwd));
cd(home_dir);
fpth_with_testing_data = fullfile("C:\Users\ldd77\OneDrive\Desktop\clustering_neuron_spikes_with_deep_learning\Data\data_to_test_smart_expansion_manipulation");

list_of_all_tetrode_files = struct2table(dir(fullfile(fpth_with_testing_data,"**/*.mat*")));

%now get a config file and set some parameters for saving 
config = spikesort_config();
config.RECORDING_NAME = "1_600Neuron300SecondRecordingWithLevel1Noise";
config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");

%now create a file to save results to 
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,config.RECORDING_NAME+"_with_smart_expand");

%now tell the algorithm to smart_expand_cluster_ver_2.m
config.USE_SMART_EXPANSION_VER_2 = true;

%reduce the number of z scores that will be tested
config.DEFAULT_CLUSTERING_Z_SCORES = [3];

%now run the clustering algorithm on the small subset for testing
run_entire_clustering_algorithm_ver_2(config);
end