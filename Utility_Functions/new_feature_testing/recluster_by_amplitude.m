function [] = recluster_by_amplitude()
%format the path
home_dir = cd("..");
cd("..");
disp(pwd);
addpath(genpath(fullfile(pwd,"Utility_Functions")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Grading_scripts")));
addpath(genpath(fullfile(pwd,"Neural_Networks")));
cd(home_dir);

%get a config file
config = spikesort_config();
config.RECORDING_NAME = "10_600Neuron300SecondRecordingWithLevel10Noise";


version_str = "_pk_amp";
% set config parameters given the system
if contains(pwd,"10595")
    config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
    config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
    config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
    blind_pass_table = importdata("/scratch2/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/subset_10_600Neuron300SecondRecordingWithLevel10Noise_2_ch/blind_pass_table.mat");
elseif contains(pwd,"C:\Users\ldd77\")
    % ext_drive_fp = "F:";
    config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
    config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
    config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
    blind_pass_table = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\3_and_4_sample.mat");
end

config.ground_truth_cell_array = importdata(config.GT_FP);
config.debug_with_ground_truth = true;
config.use_new_spike_detection = false;
config.has_ground_truth = true;

config.BLIND_PASS_DIR_PRECOMPUTED = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"testing_cluster_splitting_population"+version_str));


only_sample = false;
if only_sample
    tetrode_list = strcat("t",string(1:15:285));
    c1 = ismember(blind_pass_table{:,"Tetrode"},tetrode_list);
    blind_pass_table = blind_pass_table(c1,:);
end
load("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\subset_10_600Neuron300SecondRecordingWithLevel10Noise_2_ch\mean_and_std\mean_and_std.mat","channel_wise_means","channel_wise_std")
blind_pass_table = add_highest_amplitude_channel_col(blind_pass_table);
blind_pass_table = add_amplitude_per_channel_col(blind_pass_table);
config.error_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"error_reports"));
disp(config.BLIND_PASS_DIR_PRECOMPUTED);
bp_table_after_splitting_save_name = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"tetrode_peaks_with_new_dims.mat");
disp(bp_table_after_splitting_save_name);
if ~isfile(bp_table_after_splitting_save_name)
    [new_data,new_pot_dims,cell_arr_of_sw] = find_new_dimension_candidates(blind_pass_table,config,'plot_the_debug',false);
    data_struct = struct();
    data_struct.new_peaks = new_data;
    data_struct.new_dims = new_pot_dims;
    data_struct.sw = cell_arr_of_sw;
    par_save(bp_table_after_splitting_save_name,data_struct);
    disp("Successfully obtained the split table")
else
    data_struct = load(bp_table_after_splitting_save_name);
    data_struct = data_struct.data_to_save;
    new_data = data_struct.new_peaks;
    new_pot_dims = data_struct.new_dims;
    cell_arr_of_sw = data_struct.sw;
    disp("Successfully loaded the split table")
end
[old_peaks,only_new_peaks] = assemble_new_tetrode_peaks_and_pcs(blind_pass_table,new_data,new_pot_dims);
% try_multiple_clustering_algos(blind_pass_table,new_data,cell_arr_of_sw,config,true)

%rerun clustering

config.run_full_clustering = true;
config.debug_with_ground_truth = false;

new_clusters_fn = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"new_clusters.mat"));
if ~isfile(new_clusters_fn)
    new_clusters = try_various_top_candiadate_reclustering([old_peaks,only_new_peaks],blind_pass_table,config,cell_arr_of_sw,new_pot_dims,channel_wise_means,channel_wise_std);
    par_save(new_clusters_fn,new_clusters);
else
    new_clusters = importdata(new_clusters_fn);
end


end