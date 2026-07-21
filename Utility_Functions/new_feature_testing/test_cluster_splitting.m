function [] = test_cluster_splitting()
%format the path
home_dir = cd("..");
cd("..");
disp(pwd);
addpath(genpath(fullfile(pwd,"Utility_Functions")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Grading_scripts")));
cd(home_dir);

%get a config file
config = spikesort_config();

% set config parameters given the system
if contains(pwd,"10595")
    config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
    config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
    config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
    blind_pass_table = importdata("/scratch2/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/all_pmv_10_600Neuron300SecondRecordingWithLevel10Noise_4_ch_07_19_2026/blind_pass_table.mat");
elseif contains(pwd,"C:\Users\ldd77\")
    % ext_drive_fp = "F:";
    config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
    config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
    config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
    blind_pass_table = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\f1_clustering_tests_10_600Neuron300SecondRecordingWithLevel10Noise\blind_pass_table.mat");
end

config.ground_truth_cell_array = importdata(config.GT_FP);
config.debug_with_ground_truth = true;
config.use_new_spike_detection = false;

bp_table_after_splitting_save_place = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"testing_cluster_splitting_population"));
bp_table_after_splitting_save_name = fullfile(bp_table_after_splitting_save_place,"bp_table_after_splitting.mat");

if ~isfile(bp_table_after_splitting_save_name)
    bp_table_after_splitting = split_clusters_with_alt_dimensions(blind_pass_table,config);
    par_save(bp_table_after_splitting_save_name,bp_table_after_splitting);
else
    bp_table_after_splitting = importdata(bp_table_after_splitting_save_name);
end




end