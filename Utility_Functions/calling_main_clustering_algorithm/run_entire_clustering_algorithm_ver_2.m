function [blind_pass_table,fp_to_blind_pass_table,config] = run_entire_clustering_algorithm_ver_2(config,varargin)
%varagin will overwrite specific values if they are passed with certain key_value pairs
%these are used to overwrite the default and allow for easier testing since
%much of the pipeline depends on this function
%valid key-pairs
%"ordered_list_of_channels": string array in the format ["c1.mat","c2.mat","c3.mat"]
scale_factor = config.SCALE_FACTOR;
dir_with_channel_recordings = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
num_dps = config.NUM_DPTS_TO_SLICE;

%create a directory to log errors
config.error_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"error_reports"));
%check if there's a ground truth data set available
%if ground truth is available we can run extra debugging steps which are
%helpful when testing the pipeline
if ~isempty(config.GT_FP)
    try
        ground_truth_cell_array = importdata(config.GT_FP);
        config.has_ground_truth = true;
        config.dir_to_save_debug_files_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"DEBUG"));
        config.ground_truth_cell_array = ground_truth_cell_array;
    catch
        disp("Unable to load the ground truth dataset");
        disp(config.GT_FP);
        config.has_ground_truth = false;
    end
end

if config.use_new_spike_detection
    z_score_or_multiplier = "Multiplier";
else
    z_score_or_multiplier = "Z Score";
end
%create the directory for the template files
create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"Shape_Template_PNGs"));

% step 1: load the timestamps into memory
timestamps = importdata(config.TIMESTAMP_FP);
disp("Finished Importing timestamps for recording")

%step 2: read the precomputed dir from the config
precomputed_dir = config.BLIND_PASS_DIR_PRECOMPUTED;
disp("Finished setting the blind pass directory")

%step 3: get list of existing files in the precomputed dir
%doing this enables us to tell which parts of the algorithm can be
%skipped as to avoid repetition
list_of_existing_files =struct2table(dir(fullfile(precomputed_dir,"**",".")));
rows_to_exclude = string(list_of_existing_files{:,"name"}) == "." | string(list_of_existing_files{:,"name"})=="..";
list_of_existing_files(rows_to_exclude,:) = [];

% Step 4: Get ordered List of Channels
if isempty(varargin) || all(~cell2mat(cellfun(@(x) x=="ordered_list_of_channels", varargin, 'UniformOutput', false)))
    ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);
else
    ordered_list_of_channels = varargin{find(cell2mat(cellfun(@(x) x=="ordered_list_of_channels", varargin, 'UniformOutput', false)),1)+1};
end


% Step 5: Get the Min Threshold
min_threshold = config.NUM_OF_STD_ABOVE_MEAN;


what_is_computed = fullfile(string(list_of_existing_files{:,"folder"}),string(list_of_existing_files{:,"name"}));
config.ALREADY_DONE_FILES = what_is_computed;

% step 6: get or make the z_score channel data directory (only done once)

if ~isfolder(fullfile(precomputed_dir,"z_score")) %means that the z_score folder is already computed and we will skip computing it again
    z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"z_score")); %not yet computed
else
    z_score_dir = fullfile(precomputed_dir,"z_score");
end


% create a file where bandpass filtered data will be stored
% we'll store it in the default output data is
dir_to_store_filtered_data = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"filtered_data"));
if config.use_bandpass && ~isfile(fullfile(precomputed_dir,"finished_filtering.txt"))
    apply_filter(ordered_list_of_channels,config,dir_to_store_filtered_data,dir_with_channel_recordings)
    f_id = fopen(fullfile(precomputed_dir,"finished_filtering.txt"),'w');
    fclose(f_id);
    %overwrite the channel directory with your filtered data
    dir_with_channel_recordings = dir_to_store_filtered_data;
end


disp("Finished filtering data")

% step 7: get the mean and std of all channels the z score is also
% calculated here
mean_and_std_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"mean_and_std"));
if ~isfile(fullfile(mean_and_std_dir,"mean_and_std.mat"))
    beginning_time = tic;
    [channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,scale_factor,config,what_is_computed); %will get the mean and std of every channel and calculate z_score for data set if not yet created
    save(fullfile(mean_and_std_dir,"mean_and_std.mat"),"channel_wise_means","channel_wise_std");
    end_time = toc(beginning_time);
    fprintf("Finished Getting mean and std, it took %.2f seconds\n",end_time);
else
    load(fullfile(mean_and_std_dir,"mean_and_std.mat"),"channel_wise_means","channel_wise_std");
end
%step 8: Get the channel groupings AKA artificial tetrodes
art_tetr_array = config.ART_TETR_ARRAY;


%step 9 use a for loop to cycle through all z-scores listed in the config
%file



% step 9a: get all potential spikes with the lowest allowable z score
% desired
%all spikes of higher z scores will be included in these
%for higher z score's we'll simply filter spike windows by the z score of
%the spike
%this provides a significant boost in performance

if ~config.use_new_spike_detection
    lowest_bound_spikes_per_channel_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spikes_per_channel min_z_score "+string(min(config.DEFAULT_CLUSTERING_Z_SCORES))));
else
    lowest_bound_spikes_per_channel_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spikes_per_channel min_mult "+string(min(config.Multipliers))));
end
beginning_time = tic;

if ~config.use_new_spike_detection
    [multipliers_in_mv,cell_array_of_all_spikes_per_channel,pk_vals_cell_array] = detect_spikes_ver_2(lowest_bound_spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,min(config.DEFAULT_CLUSTERING_Z_SCORES),scale_factor,config);
    end_time = toc(beginning_time);
    fprintf("Finished cutting spikes per channel for "+z_score_or_multiplier+" %.2f, it took %.2f seconds\n",min(config.DEFAULT_CLUSTERING_Z_SCORES),end_time);
else
    %multipliers_in_mv is the threshold values
    %these will be used later on
    [multipliers_in_mv,cell_array_of_all_spikes_per_channel,pk_vals_cell_array ]= use_ic_spike_det(lowest_bound_spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,scale_factor,config,config.Multipliers);
    
end
config.Multipliers_in_mv = multipliers_in_mv;

% if the ground truth is available then we can use the spikes found in the
% previous step to see which channel has the maximum amount of each
% neuron's data
if config.has_ground_truth && config.debug_with_ground_truth
    config = check_ground_truth_appearence_per_channel(ground_truth_cell_array,multipliers_in_mv,ordered_list_of_channels,cell_array_of_all_spikes_per_channel,pk_vals_cell_array,config);
    config.plot_counter = 1;
end

%step 9b get the spike windows of the smallest z score in the config
%by all subsequent z score tests will be much faster as they will simply
%perform a logical indexing of the lowest bound
%this offers a significant increase in performance

%depending on the method we will either filter spikes by their z score or
%by the thresholds returned by use_ic_spike_det
if ~config.use_new_spike_detection
    thresholds_to_check = config.DEFAULT_CLUSTERING_Z_SCORES;
    thresholds_to_check = sort(thresholds_to_check,'ascend');
else
    thresholds_to_check = 1:length(config.Multipliers);
end
lowest_bound_threshold = min(config.Multipliers);

lowest_bound_spike_windows_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spike_windows min_z_score " + string(lowest_bound_threshold) + " num dps "+ string(num_dps)));
get_lowest_bound_spike_windows(ordered_list_of_channels,lowest_bound_spikes_per_channel_dir,lowest_bound_threshold,num_dps,z_score_dir,lowest_bound_spike_windows_dir,config)


if config.has_ground_truth && config.debug_with_ground_truth
    config = check_ground_truth_appearence_per_channel(ground_truth_cell_array,multipliers_in_mv,ordered_list_of_channels,cell_array_of_all_spikes_per_channel,pk_vals_cell_array,config);
    get_unit_detection_after_spike_cutting(config,lowest_bound_spike_windows_dir,ground_truth_cell_array);
end

% step 9d: get maps of each tetrode to its spikes
beginning_time = tic;
if ~config.use_new_spike_detection
    dictionaries_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"dictionaries min_z_score "+string(config.DEFAULT_CLUSTERING_Z_SCORES(1))+ " num_dps "+string(num_dps)));
else
    dictionaries_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"dictionaries multiplier "+string(config.Multipliers(1))+ " num_dps "+string(num_dps)));
end
% disp("the dictionaries dir")
% disp(dictionaries_dir)
config.dictionaries_dir = dictionaries_dir;
if ~isfile(fullfile(precomputed_dir,"finished_dicts.txt"))
    get_dictionaries_of_all_spikes_ver_3(art_tetr_array,lowest_bound_spike_windows_dir,dir_with_channel_recordings,timestamps,num_dps,scale_factor,dictionaries_dir,config,min_threshold);
    fid = fopen(fullfile(precomputed_dir,"finished_dicts.txt"),'w');
    fclose(fid);
end
end_time = toc(beginning_time);
fprintf('Getting dictionaries took: %f\n',end_time)
%tetrode_dictionary
%keys: "t" + tetrode number
%values: all channels which are part of the current dictionary
%spike_tetrode_dictionary
%keys: "t" + tetrode number
%values: the spikes for the current tetrode organized as follows
%[numwires, numspikes, numdp] = size(raw);
%numwires: number of channels
%numspikes: number of spikes
%numdp: number of datapoints
%timing_tetrode_dictionary
%channel_to_tetrode_dictionary
%keys: "c" + channel number
%values: tetrode which the current channel belongs to
%spiking_channel_tetrode_dictionary
%keys: "t"+ tetrode number
%values: a list of which channel was the actual spiking channel, ordered in the same way as spike_tetrode_dictionary
%spike_tetrode_dictionary_samples_format
%keys: "t"+tetrode number
%values: the spikes for the current tetrode organzied as follows
%[numdp, numspikes, numswires] = size(raw);
%numwires: number of channels
%numspikes: number of spikes
%numdp: number of datapoints
%timing_tetrode_dictionary
% number_of_non_empty_tetrodes = check_how_many_tetrodes_have_more_than_zero_spikes(spike_tetrode_dictionary);
% disp("Non Empty Tetrodes:" + string(number_of_non_empty_tetrodes))
% clc;


if config.has_ground_truth && config.debug_with_ground_truth
    config =check_unit_detection_after_dictionary_assembly(config,dictionaries_dir,ground_truth_cell_array,multipliers_in_mv);
end

channels_without_formatting = str2double(strrep(strrep(ordered_list_of_channels,"c",""),".mat",""));
if ~isfile(fullfile(precomputed_dir,"blind_pass.txt"))
    % min_threshold = thresholds_to_check(threshold_idx);





    % Step 9e: Run Clustering Algorithm
    beginning_time = tic;
    run_clustering_algorithm_on_desired_tetrodes_ver_4(channel_wise_means,channel_wise_std,min_threshold,dir_with_channel_recordings,dictionaries_dir,config);
    % run_clustering_algorithm_on_desired_tetrodes_ver_4(channel_wise_means,channel_wise_std,number_of_std_above_means,dir_with_channel_recordings,dictionaries_dir,config)
    end_time = toc(beginning_time);
    fprintf("Core Clustering "+z_score_or_multiplier+" finished, it took %.2f seconds\n",end_time);

    file_name = "blind_pass.txt";
    file_id = fopen(fullfile(precomputed_dir,file_name),'w');
    fclose(file_id);
else
    disp("Blind pass has already been run.")
    disp("If you'd like it to be recomputed then delete blind_pass.txt or change the save directory")
end

%step 11: read the results of the blind pass into a table
fp_to_blind_pass_table =create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"blind_pass_table"));
if ~isfile(fullfile(fp_to_blind_pass_table,"blind_pass_table.mat"))
    blind_pass_table = get_table_of_all_tetrodes_that_finished_blind_pass(config);
    %save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table")
    par_save(fullfile(fp_to_blind_pass_table,"blind_pass_table.mat"),blind_pass_table);
else
    blind_pass_table = importdata(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"));
    disp("A Blind Pass Table Has Been Found in your precomputed directory and will be loaded.")
    disp("If you wish to recreate the blind pass table please specficy different directory or delete existing blind pass table.")
end
disp(string(height(blind_pass_table)) + " Tetrodes created clusters")
%disp(size(blind_pass_table));
% step 12: Grade the blind pass results
beginning_time = tic;
disp("Beginning Grading")
if ~isfile(fullfile(precomputed_dir,"finished_grading.txt"))
    blind_pass_table = get_grades_and_grades_fp_col(blind_pass_table,config);
    %save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table")
    par_save(fullfile(fp_to_blind_pass_table,"blind_pass_table.mat"),blind_pass_table);
    file_name = "finished_grading.txt";
    file_id = fopen(fullfile(precomputed_dir,file_name),'w');
    fclose(file_id);
else
    disp("Grades have already been added to your blind pass table. Skipping Grading");
    disp("To regrade, delete finished_grading.txt");
end
end_time = toc(beginning_time);
fprintf("Finished grading, it took %.2f seconds\n",end_time);

%step 13: Add The Mean Waveform, idx, and timestamps of the spikes col
if ~isfile(fullfile(precomputed_dir,"finished_adding_mw.txt"))
    blind_pass_table = get_template_spike_idx_and_ts_for_clusters(blind_pass_table,config);
    %save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table")
    par_save(fullfile(fp_to_blind_pass_table,"blind_pass_table.mat"),blind_pass_table);
    file_name = "finished_adding_mw.txt";
    file_id = fopen(fullfile(precomputed_dir,file_name),'w');
    fclose(file_id);
else
    disp("Mean waveforms have already been added to your blind pass table. Skipping getting.");
    disp("To overwrite current waveforms, delete finished_adding_mw.txt");
end

% Add the mean wavefrom by stds from cluster center
% if ~isfile(fullfile(precomputed_dir,"finished_adding_mw_by_stds.txt"))
%     blind_pass_table = add_mean_wf_based_in_std_from_cluster_center(blind_pass_table,config);
%     par_save(fullfile(fp_to_blind_pass_table,"blind_pass_table.mat"),blind_pass_table);
%     file_name = "finished_adding_mw_by_stds.txt";
%     file_id = fopen(fullfile(precomputed_dir,file_name),'w');
%     fclose(file_id);
% else
%     disp("Mean Waveforms by std have already been added to your blind pass table. Skipping getting");
%     disp("to overwrite current mean waveforms by std, delete finished_adding_mw_by_stds.txt");
% end

%step 15: add the neuron or MUA or not col
if ~ismember(fullfile(precomputed_dir,"finished_adding_mua_or_not_col.txt"),what_is_computed)
    blind_pass_table = add_is_neuron_col(blind_pass_table,config);
    par_save(fullfile(fp_to_blind_pass_table,"blind_pass_table.mat"),blind_pass_table);
    %save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table")
    file_name = "finished_adding_mua_or_not_col.txt";
    file_id = fopen(fullfile(precomputed_dir,file_name),'w');
    fclose(file_id);
else
    disp("is neuron or not column exists. Skipping.")
    disp("To redo the column, delete inished_adding_mua_or_not_col.txt")
end

% add the recording name to the blind pass table
blind_pass_table.recording_name = repelem(config.RECORDING_NAME,size(blind_pass_table,1),1);

%step 16: save the blind pass table to the desired file
%save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table");
% 
if config.use_new_spike_detection
    all_vars = setdiff(string(blind_pass_table.Properties.VariableNames),"Z Score");
    blind_pass_table.Multiplier = blind_pass_table.("Z Score");
    blind_pass_table = blind_pass_table(:,["Multiplier",all_vars]);
end
par_save(fullfile(fp_to_blind_pass_table,"blind_pass_table.mat"),blind_pass_table);
%fp_to_blind_pass_table = fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat");


%enter the tinkering around phase


end