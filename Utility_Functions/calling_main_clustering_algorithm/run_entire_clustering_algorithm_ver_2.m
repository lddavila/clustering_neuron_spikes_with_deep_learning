function [blind_pass_table,fp_to_blind_pass_table,config] = run_entire_clustering_algorithm_ver_2(config)
scale_factor = config.SCALE_FACTOR;
dir_with_channel_recordings = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
num_dps = config.NUM_DPTS_TO_SLICE;

%create the directory for the template files
create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"Shape_Template_PNGs"))

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
ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);

% Step 5: Get the Min Threshold
min_threshold = config.NUM_OF_STD_ABOVE_MEAN;


what_is_computed = fullfile(string(list_of_existing_files{:,"folder"}),string(list_of_existing_files{:,"name"}));
config.ALREADY_DONE_FILES = what_is_computed;

% step 6: get or make the z_score channel data directory (only done once)
if ~ismember(fullfile(precomputed_dir,"z_score"),what_is_computed) %means that the z_score matrix is already computed and we will skip computing it again
    z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"z_score")); %not yet computed
else
    z_score_dir = fullfile(precomputed_dir,"z_score");
end
disp("Finished Creating Z Score Directory");
% disp(z_score_dir);

% step 7: get the mean and std of all channels the z score is also
% calculated here
beginning_time = tic;
[channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,scale_factor,config,what_is_computed); %will get the mean and std of every channel and calculate z_score for data set if not yet created
mean_and_std_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"mean_and_std"));
save(fullfile(mean_and_std_dir,"mean_and_std.mat"),"channel_wise_means","channel_wise_std");

end_time = toc(beginning_time);
fprintf("Finished Getting mean and std, it took %f seconds\n",end_time)
%step 8: Get the channel groupings
% clc;
art_tetr_array = config.ART_TETR_ARRAY;


%step 9 use a for loop to cycle through all z-scores listed in the config
%file
z_scores_to_check = config.DEFAULT_CLUSTERING_Z_SCORES;

if ~ismember(fullfile(precomputed_dir,"blind_pass.txt"),what_is_computed)
    for min_z_score=z_scores_to_check
        % if what_is_pre_computed is not empty then we can skip several of the steps and just load the data
        %   each element of "what_is_precomputed" is a string telling you what is already done

        beginning_time = tic;
        % step 9b: get potential spikes from continuous recordings
        spikes_per_chan_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spikes_per_channel min_z_score "+string(min_z_score)));
        if ~ismember(fullfile(spikes_per_chan_dir,"spikes_per_channel.mat"),what_is_computed)
            spikes_per_channel = detect_spikes_ver_2(ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,min_z_score,scale_factor,config);
            save(fullfile(spikes_per_chan_dir,"spikes_per_channel.mat"),"spikes_per_channel");
        else
            disp("spikes_per_channel min_z_score "+ string(min_z_score)+ " has been detected and will be skipped.")
            disp("To recalculate delete the original or change your precomputed directory.")
            load(fullfile(precomputed_dir,"spikes_per_channel min_z_score " + string(min_z_score),"spikes_per_channel.mat"), "spikes_per_channel")
        end
        end_time = toc(beginning_time);
        fprintf("Finished cutting spikes per channel for z score %f, it took %f seconds\n",min_z_score,end_time);


        % step 9c; Get all the data points from the potential spikes
        beginning_time = tic;
        spike_windows_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spike_windows min_z_score " + string(min_z_score) + " num dps "+ string(num_dps)));
        if ~ismember(fullfile(spike_windows_dir,"spike_windows.mat"),what_is_computed)
            spike_windows = get_spike_windows_ver_2(ordered_list_of_channels,spikes_per_channel,min_z_score,num_dps,z_score_dir,config);
            %each array is made up of 4 numbers:
            %the first is the beginning of the spike window
            %the second is the end of the spike_window
            %the third is the original channel of the spike
            %the fourth is the original the peak of the spike according to find_peaks'
            save(fullfile(spike_windows_dir,"spike_windows.mat"),"spike_windows");
        else
            disp("spike_windows min_z_score " + string(min_z_score) + " num dps " + string(num_dps) + " has been detected and will be skipped.")
            disp("To recalculate delete the original or change your precomputed directory.")
            load(fullfile(precomputed_dir,"spike_windows min_z_score "+string(min_z_score)+" num dps "+string(num_dps),"spike_windows.mat"),"spike_windows")
        end
        end_time = toc(beginning_time);
        fprintf("Finished getting spike windows for z score %f, it took %f seconds\n",min_z_score,end_time);


        beginning_time = tic;
        dictionaries_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"dictionaries min_z_score "+string(min_z_score)+ " num_dps "+string(num_dps)));
        % step 9d: get maps of each tetrode to its spikes
        if ~ismember(dictionaries_dir,what_is_computed)
            % clc;
            get_dictionaries_of_all_spikes_ver_3(art_tetr_array,spike_windows,dir_with_channel_recordings,timestamps,num_dps,scale_factor,dictionaries_dir,config);
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

        else
            disp("dictionaries min_z_score " + string(min_z_score) + " num_dps " + string(num_dps) +" has been detected and will not be recreated.");
            disp("To recalculate delete the original or change your precomputed directory.")

        end
        end_time = toc(beginning_time);
        fprintf('Getting dictionaries took: %f\n',end_time)


        % Step 9e: Run Clustering Algorithm
        % close all;

        % clc;

        % disp(size(array_of_desired_tetrodes));
        beginning_time = tic;

        initial_tetrode_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"initial_pass min z_score"+string(min_z_score)));
        initial_tetrode_results_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"initial_pass_results min z_score " + string(min_z_score)));
        [~,~,~] = run_clustering_algorithm_on_desired_tetrodes_ver_3(channel_wise_means,channel_wise_std,min_threshold,dir_with_channel_recordings,dictionaries_dir,initial_tetrode_dir,initial_tetrode_results_dir,config);
        end_time = toc(beginning_time);
        fprintf("Core Clustering for z score %f finished, it took %f seconds\n",min_z_score,end_time);
        file_name = "blind_pass.txt";
        file_id = fopen(fullfile(precomputed_dir,file_name),'w');
        fclose(file_id);
    end
else
    disp("Blind pass has already been run.")
    disp("If you'd like it to be recomputed then delete blind_pass.txt or change the save directory")
end

%step 11: read the results of the blind pass into a table
create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"blind_pass_table"));
if ~ismember(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),what_is_computed)
    blind_pass_table = get_table_of_all_tetrodes_that_finished_blind_pass(config);
    save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table")
else
    blind_pass_table = importdata(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"));
    disp("A Blind Pass Table Has Been Found in your precomputed directory and will be loaded.")
    disp("If you wish to recreate the blind pass table please specficy different directory or delete existing blind pass table.")
end
disp("blind_pass_table size")
disp(size(blind_pass_table));
% step 12: Grade the blind pass results
beginning_time = tic;
disp("Beginning Grading")
if ~ismember(fullfile(precomputed_dir,"finished_grading.txt"),what_is_computed)
    blind_pass_table = get_grades_and_grades_fp_col(blind_pass_table,config);
    save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table")
    file_name = "finished_grading.txt";
    file_id = fopen(fullfile(precomputed_dir,file_name),'w');
    fclose(file_id);
else
    disp("Grades have already been added to your blind pass table. Skipping Grading");
    disp("To regrade, delete finished_grading.txt");
end
end_time = toc(beginning_time);
fprintf("Finished grading, it took %f seconds\n",end_time);

%step 13: Add The Mean Waveform, idx, and timestamps of the spikes col
if ~ismember(fullfile(precomputed_dir,"finished_adding_mw.txt"),what_is_computed)
    blind_pass_table = get_template_spike_idx_and_ts_for_clusters(blind_pass_table);
    save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table")
    file_name = "finished_adding_mw.txt";
    file_id = fopen(fullfile(precomputed_dir,file_name),'w');
    fclose(file_id);
else
    disp("Mean waveforms have already been added to your blind pass table. Skipping getting.");
    disp("To regrade, delete finished_adding_mw.txt");
end

%step 15: add the neuron or MUA or not col
if ~ismember(fullfile(precomputed_dir,"finished_adding_mua_or_not_col.txt"),what_is_computed)
    blind_pass_table = add_is_neuron_col(blind_pass_table,config);
    save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table")
    file_name = "finished_adding_mua_or_not_col.txt";
    file_id = fopen(fullfile(precomputed_dir,file_name),'w');
    fclose(file_id);
else
    disp("is neuron or not column exists. Skipping.")
    disp("To read the column, delete inished_adding_mua_or_not_col.txt")
end
%step 16: save the blind pass table to the desired file
save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table");

fp_to_blind_pass_table = fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat");

end