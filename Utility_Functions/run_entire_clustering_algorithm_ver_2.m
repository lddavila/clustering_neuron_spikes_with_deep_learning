function [has_been_computed] = run_entire_clustering_algorithm_ver_2(config)
scale_factor = config.SCALE_FACTOR;
dir_with_channel_recordings = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
num_dps = config.NUM_DPTS_TO_SLICE;

% step 1: load the timestamps into memory
timestamps = importdata(config.TIMESTAMP_FP);

%step 2: read the precomputed dir from the config
precomputed_dir = config.BLIND_PASS_DIR_PRECOMPUTED;

%step 3: read the precomputed file AKA the log file to see if any steps can
%be skipped
log_file_path = dir(config.FP_TO_STATUS_FILE);
if log_file_path.bytes == 0
    what_is_pre_computed = [];
else
    what_is_pre_computed = handle_log_file();
end

% Step 4: Get ordered List of Channels
ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);

% Step 5: Get the Min Threshold
min_threshold = config.NUM_OF_STD_ABOVE_MEAN;

% step 6: get or make the z_score channel data directory (only done once)
if ~ismember("z_score",what_is_pre_computed) %means that the z_score matrix is already computed and we will skip computing it again
    z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"z_score")); %not yet computed
    create_z_score_matrix = 1;
else
    z_score_dir = fullfile(precomputed_dir,"z_score"); %in this case it already exists
    create_z_score_matrix = 0;
    has_been_computed = [has_been_computed,"z_score"];
end

% step 7: get the mean and std of all channels
if ~ismember("mean_and_std",what_is_pre_computed) %means that the channel wise mean and standard deviation are already computed so we will skip computing them again
    [channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,create_z_score_matrix,scale_factor); %will get the mean and std of every channel and calculate z_score for data set if not yet created
    mean_and_std_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfiple(precomputed_dir,"mean_and_std"));
    save(fullfile(mean_and_std_dir,"mean_and_std.mat"),"channel_wise_means","channel_wise_std");
    has_been_computed = [has_been_computed,"mean_and_std"];
else
    load(fullfile(precomputed_dir,"mean_and_std","mean_and_std.mat"),'channel_wise_means','channel_wise_std') %loads the previously found mean and std
end

%step 8: Get the channel groupings
clc;
art_tetr_array = config.ART_TETR_ARRAY;


%step 9 use a for loop to cycle through all z-scores listed in the config
%file
z_scores_to_check = config.DEFAULT_CLUSTERING_Z_SCORES;
for min_z_score=z_scores_to_check
    % if what_is_pre_computed is not empty then we can skip several of the steps and just load the data
    %   each element of "what_is_precomputed" is a string telling you what is already done

    %step 4: create the directory to save results to if it doesn't alreay exist so you can save anything you need to it
    if isempty(what_is_pre_computed)
        precomputed_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(precomputed_dir);
    end


    has_been_computed = []; %will store what was successfully computed and saved











    % step 7: get potential spikes from continuous recordings
    %<3 causes out of memory error
    %=3 causes every tetrode to have spikes (should be impossible when there are only 10 neurons)
    %=4 causes every tetrode to have spikes (should be impossible
    %=5 causes 87 tetrodes which will cause 87 non empty tetrodes (better but still too much)
    %=6 creates huge jump to only 43 non empty tetrodes, so I think that this is the minimum needed to get ride of noise
    %=10 only 21 active tetrodes, which is probably too few given that we have 10 neurons
    %ordered_list_of_channels = ["c25","c26","c27","c28","c122","c219","c314","c315","c101","c290"];
    if ~ismember("spikes_per_channel min_z_score "+ string(min_z_score),what_is_pre_computed)
        spikes_per_chan_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(precomputed_dir+"\spikes_per_channel min_z_score "+string(min_z_score));
        spikes_per_channel = detect_spikes_ver_2(ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,min_z_score,scale_factor);
        save(fullfile(spikes_per_chan_dir,"spikes_per_channel.mat"),"spikes_per_channel");
        has_been_computed = [has_been_computed,"spikes_per_channel min_z_score"+string(min_z_score)];
    else
        load(fullfile(precomputed_dir,"spikes_per_channel min_z_score " + string(min_z_score),"spikes_per_channel.mat"), "spikes_per_channel")
    end
    % step 6; Get all the data points from the potential spikes
    if ~ismember("spike_windows min_z_score " + string(min_z_score) + " num dps " + string(num_dps),what_is_pre_computed)
        spike_windows_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spike_windows min_z_score " + string(min_z_score) + " num dps "+ string(num_dps)));
        spike_windows = get_spike_windows_ver_2(ordered_list_of_channels,spikes_per_channel,min_z_score,num_dps,z_score_dir);
        has_been_computed = [has_been_computed,"spike_windows min_z_score" + string(min_z_score) + " num dps " + string(num_dps),what_is_pre_computed];
        %each array is made up of 4 numbers:
        %the first is the beginning of the spike window
        %the second is the end of the spike_window
        %the third is the original channel of the spike
        %the fourth is the original the peak of the spike according to find_peaks
        save(fullfile(spike_windows_dir,"spike_windows.mat"),"spike_windows");
    else
        load(fullfile(precomputed_dir,"spike_windows min_z_score "+string(min_z_score)+" num dps "+string(num_dps),"spike_windows.mat"),"spike_windows")
    end




    % step 8: get maps of each tetrode to its spikes
    if ~ismember("dictionaries min_z_score " + string(min_z_score) + " num_dps " + string(num_dps),what_is_pre_computed)
        clc;
        dictionaries_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"dictionaries min_z_score "+string(min_z_score)+ " num_dps "+string(num_dps)));
        get_dictionaries_of_all_spikes_ver_3(art_tetr_array,spike_windows,dir_with_channel_recordings,timestamps,num_dps,scale_factor,dictionaries_dir);
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
        has_been_computed = [has_been_computed,"dictionaries min_z_score " + string(min_z_score) + " num_dps " + string(num_dps),what_is_pre_computed];
    else
        dictionaries_dir = fullfile(precomputed_dir,"dictionaries min_z_score "+string(min_z_score)+ " num_dps "+string(num_dps));
    end


    % Step 9: Run Clustering Algorithm
    % close all;
    clc;
    % 80 and 116 and 14
    % array_of_desired_tetrodes = get_array_of_all_tetrodes_which_contain_given_channel(54,art_tetr_array);
    % array_of_desired_tetrodes = array_of_desired_tetrodes(2:end);
    array_of_desired_tetrodes = strcat("t",string(1:size(art_tetr_array,1)));
    if ~ismember("initial_pass",what_is_pre_computed)
        initial_tetrode_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"initial_pass min z_score"+string(min_z_score)));
        initial_tetrode_results_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"initial_pass_results min z_score" + string(min_z_score)));
        [~,~,~] = run_clustering_algorithm_on_desired_tetrodes_ver_3(array_of_desired_tetrodes,channel_wise_means,channel_wise_std,min_threshold,dir_with_channel_recordings,dictionaries_dir,initial_tetrode_dir,initial_tetrode_results_dir);
        has_been_computed = [has_been_computed,"initial_pass"];


    end
end
end