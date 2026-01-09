function [] = concatenate_all_available_bp_tables_into_one(config)
[home_dir,~,~] = fileparts(mfilename('fullpath'));
cd(home_dir);
home_dir = cd("..");
addpath(genpath(pwd))
cd(home_dir)
disp("Finished adding path");

% config = spikesort_config();
disp("Finished getting config");

dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(config.parent_save_dir,"master_bp_table"));
base_path = config.base_file_path;
%get all .mat files in default results directory
table_of_all_blind_pass_tables = struct2table(dir(string(fullfile(base_path,"Default_Results_Dir", '**', '*.mat'))));

%filter down to only the blind_pass_tables 
table_of_all_blind_pass_tables = table_of_all_blind_pass_tables(string(table_of_all_blind_pass_tables{:,"name"})=="blind_pass_table.mat",:);

%concatenate all blind pass tables into a single one
col_names = [  "Z Score"
    "Tetrode"
    "Cluster"
    "grades"
    "fp_to_aligned"
    "fp_to_cleaned_clusters"
    "fp_to_reg_timestamps"
    "fp_to_reg_timestamps_of_the_spikes"
    "fp_to_sorted_spike_windows_after_purges"
    "fp_to_timestamps_rtvals"
    "cluster_idx"
    "timestamps"
    "mean_waveform_rep_wire_1"
    "mean_waveform_rep_wire_2"
    "waveforms_by_std_1"
    "waveforms_by_std_2"
    "is_neuron"
    "recording_name"
    "Max_Overlap_perc_With_Unit"
    "Max_Overlap_Unit"
    "overlap_perc_with_all_units"
    "accuracy"];

single_bp_table = cell(height(table_of_all_blind_pass_tables),1);
for i=1:height(table_of_all_blind_pass_tables)
    current_dir = string(table_of_all_blind_pass_tables{i,"folder"});
    split_recording_dir = split(current_dir,filesep);
    recording_name = string(split_recording_dir(end));
    fprintf("loading %s",fullfile(current_dir,"blind_pass_table.mat"))
    current_bp_table = importdata(fullfile(current_dir,"blind_pass_table.mat"));
    fprintf("finished loading %s",fullfile(current_dir,"blind_pass_table.mat"))
    current_bp_table = current_bp_table(:,col_names);
    
    current_bp_table.recording_name = repelem(recording_name,size(current_bp_table,1),1);
end
single_bp_table = vertcat(single_bp_table(:));
par_save(fullfile(dir_to_save_results_to,"all_channel_perms_bp_table.mat"),single_bp_table);

end