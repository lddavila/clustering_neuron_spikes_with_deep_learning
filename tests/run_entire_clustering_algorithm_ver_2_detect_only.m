function [multipliers_in_mv,cell_array_of_all_spikes_per_channel,pk_vals_cell_array,config] = detect_spikes_test(config,varargin)

use_defaults = nargin < 1 || isempty(config);
if use_defaults
    project_dir = fileparts(fileparts(mfilename("fullpath")));
    cd(project_dir); %spikesort_config only works from inside the project
    addpath(genpath(project_dir));
    config = spikesort_config();
    config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data","10_100","recordings_by_channel");
    %a new folder each run so no cached results are reused
    config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(tempdir,"detect_only_test_"+string(datetime("now","Format","yyyyMMdd_HHmmss")));
    config.use_bandpass = false; %apply_filter currently fails on row-vector recordings
    if isempty(varargin)
        varargin = {"ordered_list_of_channels",["c1.mat","c2.mat","c97.mat","c98.mat"]};
    end
    disp("Results folder: "+config.BLIND_PASS_DIR_PRECOMPUTED)
end
scale_factor = config.SCALE_FACTOR;
dir_with_channel_recordings = config.DIR_WITH_OG_CHANNEL_RECORDINGS;

%step 2: read the precomputed dir from the config
precomputed_dir = config.BLIND_PASS_DIR_PRECOMPUTED;

%step 3: get list of existing files in the precomputed dir
list_of_existing_files =struct2table(dir(fullfile(precomputed_dir,"**",".")));
rows_to_exclude = string(list_of_existing_files{:,"name"}) == "." | string(list_of_existing_files{:,"name"})=="..";
list_of_existing_files(rows_to_exclude,:) = [];

% Step 4: Get ordered List of Channels
if isempty(varargin) || all(~cell2mat(cellfun(@(x) x=="ordered_list_of_channels", varargin, 'UniformOutput', false)))
    ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);
else
    ordered_list_of_channels = varargin{find(cell2mat(cellfun(@(x) x=="ordered_list_of_channels", varargin, 'UniformOutput', false)),1)+1};
end

what_is_computed = fullfile(string(list_of_existing_files{:,"folder"}),string(list_of_existing_files{:,"name"}));
config.ALREADY_DONE_FILES = what_is_computed;

% step 6: get or make the z_score channel data directory (only done once)
if ~isfolder(fullfile(precomputed_dir,"z_score"))
    z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"z_score"));
else
    z_score_dir = fullfile(precomputed_dir,"z_score");
end

% create a file where bandpass filtered data will be stored
dir_to_store_filtered_data = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"filtered_data"));
if config.use_bandpass && ~isfile(fullfile(precomputed_dir,"finished_filtering.txt"))
    apply_filter(ordered_list_of_channels,config,dir_to_store_filtered_data,dir_with_channel_recordings)
    f_id = fopen(fullfile(precomputed_dir,"finished_filtering.txt"),'w');
    fclose(f_id);
    %overwrite the channel directory with your filtered data
    dir_with_channel_recordings = dir_to_store_filtered_data;
end

% step 7: get the mean and std of all channels the z score is also
% calculated here
mean_and_std_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"mean_and_std"));
if ~isfile(fullfile(mean_and_std_dir,"mean_and_std.mat"))
    [channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,scale_factor,config,what_is_computed);
    save(fullfile(mean_and_std_dir,"mean_and_std.mat"),"channel_wise_means","channel_wise_std");
end

% step 9a: get all potential spikes with the lowest allowable z score
lowest_bound_spikes_per_channel_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spikes_per_channel min_z_score "+string(min(config.DEFAULT_CLUSTERING_Z_SCORES))));
[multipliers_in_mv,cell_array_of_all_spikes_per_channel,pk_vals_cell_array] = detect_spikes_ver_3(lowest_bound_spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,min(config.DEFAULT_CLUSTERING_Z_SCORES),scale_factor,config);
config.Multipliers_in_mv = multipliers_in_mv;

config.test_z_score_dir = z_score_dir;
config.test_dir_with_channel_recordings = dir_with_channel_recordings;
config.test_spikes_per_channel_dir = lowest_bound_spikes_per_channel_dir;

if use_defaults
    for i=1:length(ordered_list_of_channels)
        fprintf("%s: %d spikes, thresholds for z = %s: %s\n",ordered_list_of_channels(i),length(cell_array_of_all_spikes_per_channel{i}), ...
            mat2str(config.DEFAULT_CLUSTERING_Z_SCORES),mat2str(multipliers_in_mv{i},4));
    end
end
end




