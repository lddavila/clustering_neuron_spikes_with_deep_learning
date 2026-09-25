function [] = run_only_the_waveform_stuff_for_bp_tables_on_cluster(varargin)
home_dir = cd("..");
cd("..");
addpath(genpath(fullfile(pwd,"Neural_Networks/"))); 
addpath(genpath(fullfile(pwd,"Grading_scripts")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Utility_Functions")));
cd(home_dir);

config = spikesort_config();
config.error_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"errors_from_adding_mw_to_tables"));
config.RECORDING_NAME =string(10)+"_600Neuron300SecondRecordingWithLevel"+string(10)+"Noise";
config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
if contains(pwd,"10595")
paths_of_tables = ["/scratch/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/full_set_10_600Neuron300SecondRecordingWithLevel10Noise_2_ch/prominance_and_peak_width_width_over_height/blind_pass_table/blind_pass_table.mat",...
    "/scratch/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/full_set_10_600Neuron300SecondRecordingWithLevel10Noise_3_ch/prominance_and_peak_width_width_over_height/blind_pass_table/blind_pass_table.mat",...
    "/scratch/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/full_set_10_600Neuron300SecondRecordingWithLevel10Noise_4_ch/prominance_and_peak_width_width_over_height/blind_pass_table/blind_pass_table.mat"];
else
    paths_of_tables = ["C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\from_ls6\4_ch\data_to_test_add_cluster_idx_and_ts_for_clusters_locallly\test_table.mat"];
end
for i=1:length(paths_of_tables)
    blind_pass_table = load(paths_of_tables(i));
    blind_pass_table = blind_pass_table.data_to_save;
    grades = blind_pass_table.grades;
    channels = cellfun(@(x) x(49), grades);
    blind_pass_table.channels = channels;
    blind_pass_table = get_template_spike_idx_and_ts_for_clusters(blind_pass_table,config);
    par_save(paths_of_tables(i),blind_pass_table);

end
end