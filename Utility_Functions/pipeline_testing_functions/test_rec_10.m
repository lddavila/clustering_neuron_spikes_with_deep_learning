%% set path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%% get a config
config = spikesort_config();

%% set params on the config
config.RECORDING_NAME = "10_600Neuron300SecondRecordingWithLevel10Noise";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"test_ic_2_"+config.RECORDING_NAME);
config.BLIND_PASS_DIR_PRECOMPUTED_ONLY_END = "test_ic_"+config.RECORDING_NAME;
disp("Recording Name");
disp(config.RECORDING_NAME)
config.debug_with_ground_truth = true;
startup;


ext_drive_fp = "F:";
config.GT_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"ground_truth","ground_truth.mat");
config.TIMESTAMP_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(ext_drive_fp,config.RECORDING_NAME,"recordings_by_channel");
% config.ART_TETR_ARRAY = config.ART_TETR_ARRAY(1,:);
config.BLIND_PASS_DIR_PRECOMPUTED = strrep(config.BLIND_PASS_DIR_PRECOMPUTED,fullfile(config.base_file_path,"Default_Results_Dir"),"F:");

%% run the spike sorter
run_entire_clustering_algorithm_ver_2(config);













