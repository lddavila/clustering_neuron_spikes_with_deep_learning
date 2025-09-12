function [meets_acc_ratio,blind_pass_table] = modified_run_entire_clustering_algorithm_for_img_analysis(config,timestamps,spike_windows_dir,channels,channel_wise_means,channel_wise_std,tetrode_number)
%this version differs from the mainline production version because it
%optimizes for the new feature of finding the best threshold for a tetrode
%by looking at an n-dimension image
%it is also (hopefully) faster because it avoids recreating the dictionaries every time
%it avoids this by finding only 1 dictionary (with lowest boundry
%threshold) and mask the spikes in all subsequent dictionary creation
%thus skipping a lot of precessing work
meets_acc_ratio = false;

scale_factor = config.SCALE_FACTOR;
dir_with_channel_recordings = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
num_dps = config.NUM_DPTS_TO_SLICE;



%step 3: get list of existing files in the precomputed dir
%doing this enables us to tell which parts of the algorithm can be
%skipped as to avoid repetition
list_of_existing_files =struct2table(dir(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"**",".")));
rows_to_exclude = string(list_of_existing_files{:,"name"}) == "." | string(list_of_existing_files{:,"name"})=="..";
list_of_existing_files(rows_to_exclude,:) = [];

% Step 4: Get ordered List of Channels
ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);

% Step 5: Get the Min Threshold
min_threshold = config.NUM_OF_STD_ABOVE_MEAN;

what_is_computed = fullfile(string(list_of_existing_files{:,"folder"}),string(list_of_existing_files{:,"name"}));
config.ALREADY_DONE_FILES = what_is_computed;


%we also skip getting the z score directory as we assume that it has
%already been gotten 
%if ~ismember(fullfile(precomputed_dir,"z_score"),what_is_computed) %means that the z_score matrix is already computed and we will skip computing it again
%    z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"z_score")); %not yet computed
%else
%    z_score_dir = fullfile(precomputed_dir,"z_score");
%end
%disp("Finished Creating Z Score Directory");
% disp(z_score_dir);

% step 7: we skip gettting channel wise statistics again because we assume
% it is done ahead of time
% beginning_time = tic;
% [channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,scale_factor,config,what_is_computed); %will get the mean and std of every channel and calculate z_score for data set if not yet created
% mean_and_std_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"mean_and_std"));
% save(fullfile(mean_and_std_dir,"mean_and_std.mat"),"channel_wise_means","channel_wise_std");
% end_time = toc(beginning_time);
% fprintf("Finished Getting mean and std, it took %f seconds\n",end_time)
%step 8: Get the channel groupings
% clc;
art_tetr_array = config.ART_TETR_ARRAY;


%step 9 use a for loop to cycle through all z-scores listed in the config
%file
z_scores_to_check = config.DEFAULT_CLUSTERING_Z_SCORES;


accuracy_threshold = 80;
for min_z_score = z_scores_to_check %this for loop is probably redundant because we'll only ever be doing 1 tetrode at 1 z score at a time in this version

    % if what_is_pre_computed is not empty then we can skip several of the steps and just load the data
    %   each element of "what_is_precomputed" is a string telling you what is already done

    %we do not perform any spike detection here as we assume it was already
    %done ahead of time and we only need to access the spike cutting data
    %beginning_time = tic;
    % step 9b: get potential spikes from continuous recordings
    %spikes_per_channel_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spikes_per_channel min_z_score "+string(min_z_score)));
    %detect_spikes_ver_2(spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,min_z_score,scale_factor,config);
    %end_time = toc(beginning_time);
    %fprintf("Finished cutting spikes per channel for z score %i, it took %f seconds\n",min_z_score,end_time);


    % step 9c; Get all the data points from the potential spikes
    beginning_time = tic;

    spike_windows_dir_new = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"spike_windows min_z_score " + string(min_z_score) + " num dps "+ string(num_dps))+" "+string(tetrode_number));
    get_spike_windows_ver_3(channels,min_z_score,spike_windows_dir,spike_windows_dir_new);
    end_time = toc(beginning_time);
    % fprintf("Finished getting spike windows for z score %f, it took %f seconds\n",min_z_score,end_time);


    beginning_time = tic;
    dictionaries_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"dictionaries min_z_score "+string(min_z_score)+ " num_dps "+string(num_dps))+" "+string(tetrode_number));
    % step 9d: get maps of each tetrode to its spikes

    % clc;
    get_dictionaries_of_all_spikes_ver_3(channels,spike_windows_dir_new,dir_with_channel_recordings,timestamps,num_dps,scale_factor,dictionaries_dir,config);
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


    end_time = toc(beginning_time);
    % fprintf('Getting dictionaries took: %f\n',end_time)


    % Step 9e: Run Clustering Algorithm
    % close all;

    % clc;

    % disp(size(array_of_desired_tetrodes));
    beginning_time = tic;

    initial_tetrode_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"initial_pass min z_score"+string(min_z_score))+" "+string(tetrode_number));
    initial_tetrode_results_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"initial_pass_results min z_score " + string(min_z_score)))+" "+string(tetrode_number);
    [~,~,~] = run_clustering_algorithm_on_desired_tetrodes_ver_3(channel_wise_means,channel_wise_std,min_threshold,dir_with_channel_recordings,dictionaries_dir,initial_tetrode_dir,initial_tetrode_results_dir,config);
    end_time = toc(beginning_time);
    % fprintf("Core Clustering for z score %f finished, it took %f seconds\n",min_z_score,end_time);
    % file_name = "blind_pass.txt";
    % file_id = fopen(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,file_name),'w');
    % fclose(file_id);



    %step 11: read the results of the blind pass into a table   
    blind_pass_table = table(fullfile(initial_tetrode_results_dir,"t1 output.mat"),fullfile(initial_tetrode_results_dir,"t1 reg_timestamps.mat"),'VariableNames', ...
    ["fp_to_output","fp_to_reg_timestamps_of_the_spikes"]);
    if ~isfile(blind_pass_table{1,"fp_to_output"}) || ~isfile(blind_pass_table{1,"fp_to_reg_timestamps_of_the_spikes"})
        meets_acc_ratio = false;
        blind_pass_table = [];
        try
        rmdir(dictionaries_dir,'s');
        rmdir(initial_tetrode_dir,'s');
        rmdir(initial_tetrode_results_dir,'s')
        rmdir(spike_windows_dir_new,'s')
        catch
        end
        return;
    end
    % disp("Finished getting basic blind pass table")
    % save(fullfile(precomputed_dir,"blind_pass_table","blind_pass_table.mat"),"blind_pass_table")

    %now add the clusters to the blind pass table
    % disp("Abount to get clusters")
    blind_pass_table = add_clusters_to_bp_table(blind_pass_table);
    % disp("Finished adding clusters");

    %now we compute the accuracy directly for the blind pass table
    % disp("About to add accuracy");
    blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,config,timestamps);
    blind_pass_table= add_accuracy_col_modified(config,blind_pass_table);
    % disp("Finished getting accuracy")

    %now get the ratio of clusters above 70% accurate to clusters less than 70%
    %accuracy
    meets_acc_ratio =any(blind_pass_table{:,"accuracy"}>=accuracy_threshold);

    % disp("Finished getting blind pass table")
    %do file cleanup to ensure no necessary steps are skipped due to
    %previous permutations
    rmdir(dictionaries_dir,'s');
    rmdir(initial_tetrode_dir,'s');
    rmdir(initial_tetrode_results_dir,'s')
    rmdir(spike_windows_dir_new,'s')

    % disp("Finished cleaning up")

    % display(blind_pass_table(:,["Z Score","Tetrode","Cluster","accuracy"]))

end






end