function [] = test_logical_grouping(varargin)
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%get config file
config = spikesort_config();

%load the blind pass table
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_MASTER_TRAINING_BP_TABLE);
else
    blind_pass_table = varargin{1};
end

%test the grouping for each individual recording
unique_recording_names = unique(blind_pass_table{:,"recording_name"});  

%create a file to save recordings to
dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"logical_grouping_results"));
for i=1:length(unique_recording_names)
    current_recording = blind_pass_table(blind_pass_table{:,"recording_name"}==unique_recording_names(i),:);
    current_group_recordings = logical_grouping(current_recording,config);
    par_save(fullfile(dir_to_save_results_to,sprintf("%s.mat",unique_recording_names(i))),current_group_recordings)
end
end