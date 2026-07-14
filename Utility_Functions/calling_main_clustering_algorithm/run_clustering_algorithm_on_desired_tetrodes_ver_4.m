function [base_sw_dir] = run_clustering_algorithm_on_desired_tetrodes_ver_4(channel_wise_means,channel_wise_std,number_of_std_above_means,dir_with_channel_recordings,dictionaries_dir,config)
%this version differs from version 3 because this version tries to minimize
%the setup and cleanup costs of a parfor loop by having all setup occur
%upfront instead of a for loop which then calls parfor separately
%practical testing to follow

%to accomplish this we have to know how many total iterations need to be
%made
%this number can be derived by knowing how many thresholds and how many
%tetrodes you have available
list_of_available_dictionaries = struct2table(dir(fullfile(dictionaries_dir,"* tetrode_dictionary.mat")));

list_of_available_dictionaries = string(list_of_available_dictionaries{:,"name"});
list_of_available_tetrodes = strrep(list_of_available_dictionaries," tetrode_dictionary.mat","");


number_of_tetrodes_to_run = str2double(strrep(list_of_available_tetrodes,"t","")); %tetrodes are not necessarily linear as some may have failed at earlier stages
theoretical_max_num_tetrodes = 1:size(config.ART_TETR_ARRAY,1);
% theoretical_max_num_tetrodes = [136,14,166,10,4,5,7,8]; %REMEMBER TO REMOVE THIS LINE
number_of_tetrodes_to_run = intersect(number_of_tetrodes_to_run,theoretical_max_num_tetrodes);
if config.use_new_spike_detection
    number_of_thresholds_to_run = config.Multipliers; %multipliers might not be linear, but we have catches for that
else
    number_of_thresholds_to_run = config.DEFAULT_CLUSTERING_Z_SCORES;
end
every_permutation_of_both = combinations(number_of_thresholds_to_run,number_of_tetrodes_to_run);

filenames = repelem("",1,size(every_permutation_of_both,1));
if config.use_new_spike_detection
    all_possible_local_tetrode_dir = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"initial_pass min multiplier"+every_permutation_of_both{:,"number_of_thresholds_to_run"});
else
    all_possible_local_tetrode_dir = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"initial_pass min z_score"+every_permutation_of_both{:,"number_of_thresholds_to_run"});
end
dirs_to_create = unique(all_possible_local_tetrode_dir);
for j=1:length(dirs_to_create)
    create_a_file_if_it_doesnt_exist_and_ret_abs_path(dirs_to_create(j));
end
for j=1:length(filenames)
    local_tetrode_dir = all_possible_local_tetrode_dir(j);
    filenames(j) =fullfile(local_tetrode_dir,"t"+every_permutation_of_both{j,"number_of_tetrodes_to_run"}+".mat");
end
every_permutation_of_both.filenames = filenames.';
%it is unfeasible and redundant to load the same data many times
%we only need to load the data the equal to the number of tetrodes
sliced_every_permutation_of_both = slice_table_for_parallel_processing(every_permutation_of_both,"number_of_tetrodes_to_run");
for i=1:length(sliced_every_permutation_of_both)
    current_data = sliced_every_permutation_of_both{i};
    current_tetrode = "t"+current_data{1,"number_of_tetrodes_to_run"};
    tetrode_dictionary = importdata(fullfile(dictionaries_dir,current_tetrode+" tetrode_dictionary.mat"));
    tetrode_dictionary =tetrode_dictionary.tetrode_dictionary;

    channels_in_current_tetrode = tetrode_dictionary(current_tetrode);
    current_data.sliced_channel_wise_means = repmat(channel_wise_means(channels_in_current_tetrode),size(current_data,1),1);
    current_data.sliced_channel_stds = repmat(channel_wise_std(channels_in_current_tetrode),size(current_data,1),1);
    sliced_every_permutation_of_both{i} = current_data;
end
every_permutation_of_both = vertcat(sliced_every_permutation_of_both{:});
list_of_available_channels = struct2table(dir(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS,"*.mat")));

if config.has_ground_truth && config.debug_with_ground_truth
    config.table_of_best_rep = load(config.fp_to_table_of_best_rep,"data_to_save").data_to_save;
end
config =parallel.pool.Constant(config);


% disp(config.DIR_WITH_OG_CHANNEL_RECORDINGS);
list_of_available_channels = string(list_of_available_channels{:,"name"});
list_of_available_channels = strrep(list_of_available_channels,".mat","");
list_of_available_channels = strrep(list_of_available_channels,"c","");
list_of_available_channels = str2double(list_of_available_channels);

sliced_every_permutation_of_both = slice_table_for_parallel_processing(every_permutation_of_both,"number_of_tetrodes_to_run");

q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = height(every_permutation_of_both);
print_status_bar(num_iterations,"run_clustering_algorithm_on_desired_tetrodes_ver_4");

base_aligned_files_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.Value.BLIND_PASS_DIR_PRECOMPUTED,"aligned_wf_files"));
% base_raw_files_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.Value.BLIND_PASS_DIR_PRECOMPUTED,"filtered_raw_wf_files"));
base_sw_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.Value.BLIND_PASS_DIR_PRECOMPUTED,"aligned_spike_windows"));
% config.base_sw_dir = base_sw_dir;
%there should be a parfor on the line immediately following this one when not testing
for i=1:length(sliced_every_permutation_of_both)

    current_data = sliced_every_permutation_of_both{i};
    %get a local copy of config
    local_config = config.Value;
    % beginning_time = tic;

    current_tetrode = "t"+current_data{1,"number_of_tetrodes_to_run"};

    if local_config.has_ground_truth && local_config.debug_with_ground_truth
        local_config.table_of_best_rep = local_config.table_of_best_rep(local_config.table_of_best_rep{:,"tetrode"}==current_tetrode,:);
    end

    %check for required files
    %if all the necessary files weren't created in the previous step then
    %we cannot proceed to the next step
    c5 = isfile(fullfile(dictionaries_dir,current_tetrode+ " tetrode_dictionary.mat"));
    c6 = isfile(fullfile(dictionaries_dir,current_tetrode+" spike_tetrode_dictonary.mat"));
    c7 = isfile(fullfile(dictionaries_dir,current_tetrode+" timing_tetrode_dictionary.mat"));
    c8 = isfile(fullfile(dictionaries_dir,current_tetrode+" sorted_spike_windows.mat"));

    if ~all([c5,c6,c7,c8])
        send(q,[]);
        continue;
    end


    %by loading the dictionaries first we can minimize the number of loads
    tetrode_dictionary = load(fullfile(dictionaries_dir,current_tetrode+ " tetrode_dictionary.mat"));
    tetrode_dictionary = tetrode_dictionary.data_to_save;
    tetrode_dictionary =tetrode_dictionary.tetrode_dictionary;
    % disp(fullfile(dictionaries_dir,current_tetrode+" spike_tetrode_dictonary.mat"));
    spike_tetrode_dictionary =load(fullfile(dictionaries_dir,current_tetrode+" spike_tetrode_dictonary.mat"));
    spike_tetrode_dictionary = spike_tetrode_dictionary.data_to_save;
    spike_tetrode_dictionary = spike_tetrode_dictionary.spike_tetrode_dictionary;
    timing_tetrode_dictionary =load(fullfile(dictionaries_dir,current_tetrode+" timing_tetrode_dictionary.mat"));
    timing_tetrode_dictionary = timing_tetrode_dictionary.data_to_save;
    timing_tetrode_dictionary =timing_tetrode_dictionary.timing_tetrode_dictionary;
    sorted_spike_windows_dictionary = load(fullfile(dictionaries_dir,current_tetrode+" sorted_spike_windows.mat"));
    sorted_spike_windows_dictionary = sorted_spike_windows_dictionary.data_to_save;
    sorted_spike_windows_dictionary = sorted_spike_windows_dictionary.sorted_spike_windows_for_current_tetrode_dictionary;
    sorted_spike_windows = sorted_spike_windows_dictionary(current_tetrode);




    spike_tetrode_dictionary_samples_format =load(fullfile(dictionaries_dir,current_tetrode+" spike_tetrode_dictionary_samples_format.mat"));
    spike_tetrode_dictionary_samples_format = spike_tetrode_dictionary_samples_format.data_to_save;
    spike_tetrode_dictionary_samples_format = spike_tetrode_dictionary_samples_format.spike_tetrode_dictionary_samples_format;
    raw = spike_tetrode_dictionary(current_tetrode);
    aligned_file_name = fullfile(base_aligned_files_dir,current_tetrode+" aligned_to_peak_wf.mat");
    base_aligned_sw_name = fullfile(base_sw_dir,current_tetrode+" sorted_spike_windows_after_purges.mat");
    % raw_file_name = fullfile(base_raw_files_dir,current_tetrode+" raw_wf.mat");
    if isfile(aligned_file_name)
        base_aligned = load(aligned_file_name);
        base_aligned = base_aligned.data_to_save;
        base_aligned_idxs = 1:1:size(base_aligned,2);
    end

    for j=1:height(current_data)
        even_more_local_config = local_config;
        
        even_more_local_config.tetrode = current_tetrode;

        even_more_local_config.which_thresh = current_data{j,"number_of_thresholds_to_run"};
        if even_more_local_config.has_ground_truth && even_more_local_config.debug_with_ground_truth
            even_more_local_config.table_of_best_rep = even_more_local_config.table_of_best_rep(even_more_local_config.table_of_best_rep{:,"all_multiplier_idxs"}==even_more_local_config.which_thresh,:);
        end
        current_filename = current_data{j,"filenames"};
        %check to make sure that every channel in the current dataset is
        %actually available
        channels_in_current_tetrode = tetrode_dictionary(current_tetrode);
        all_channels_are_available = channels_in_current_tetrode==list_of_available_channels;
        if ~all(any(all_channels_are_available))
            send(q,[]);
            continue;
        end
        even_more_local_config.current_channels = channels_in_current_tetrode;

        if config.Value.use_new_spike_detection
            local_initial_tetrodes_results_dir = fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"initial_pass_results min multiplier "+ current_data{j,"number_of_thresholds_to_run"});
        else
            local_initial_tetrodes_results_dir = fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"initial_pass_results min z_score"+ current_data{j,"number_of_thresholds_to_run"});
        end
        %NO LONGER USE CAUSE REDUNDANToutput_file_name = fullfile(local_initial_tetrodes_results_dir,current_tetrode+" output.mat");
        
        %NO LONGER USE CAUSE REDUNDANTreg_ts_file_name= fullfile(local_initial_tetrodes_results_dir,current_tetrode+" reg_timestamps.mat");
        reg_ts_of_spikes_file_name =fullfile(local_initial_tetrodes_results_dir,current_tetrode+ " reg_timestamps_of_the_spikes.mat");
        peak_pcs_file_name = fullfile(local_initial_tetrodes_results_dir,current_tetrode+" peak_pcs.mat");

        %overwrite the field
        even_more_local_config.peak_pcs_file_name = peak_pcs_file_name;

        % c1 = isfile(output_file_name);
        c2 = isfile(aligned_file_name);
        % c3 = isfile(reg_ts_file_name);
        c4 = isfile(reg_ts_of_spikes_file_name);

        %if this clustering outcome already exists don't run it again
        if all([c2,c4])
            send(q,[]);
            continue;
        end

        

        %record raw's size before cutting
        raw_size_before = size(raw);

        %here we will implement the process that will allow us to save much
        %compute time in saving/loading
        %instead of getting new dictionaries for every threshold we will simply
        %apply the desired threshold indicated by the current_z_score variable

        %get the max peak value for each waveform
        max_peak_vals = max(abs(raw),[],[1,3]).';
        %get which channel each max peak value belongs to
        which_channel = sorted_spike_windows(:,3);
        %get the appropriate filter value for the given channels and current
        %min_z_score

        %make sure all rows of multipliers in mv are casted to double
        for p=1:length(even_more_local_config.Multipliers_in_mv)
            even_more_local_config.Multipliers_in_mv{p} = double(even_more_local_config.Multipliers_in_mv{p});
        end
        flat_multipliers = cell2mat(even_more_local_config.Multipliers_in_mv);
        per_channel_thresholds_for_curr_z_sc= flat_multipliers(:,current_data.number_of_thresholds_to_run ==current_data.number_of_thresholds_to_run(j) );
        per_spike_thresholds = per_channel_thresholds_for_curr_z_sc(which_channel);
        has_already_been_run = check_if_current_data_has_already_been_run(max_peak_vals,which_channel,flat_multipliers,j,raw);
        if has_already_been_run
            send(q,[]);
            continue;
        end
        % if j~=1
        %now filter out any values in raw that do not meet the threshold'
        if even_more_local_config.use_new_spike_detection
            filter_1 = max_peak_vals>=per_spike_thresholds; % a comparison in microvolts
        else
            filter_1 = abs(sorted_spike_windows(:,5)) > current_data.number_of_thresholds_to_run(j); % a comparison in z score
        end

        mutated_raw = raw(:,filter_1,:);
        

        %filter the spike windows for debugging in clustering process
        mutated_spike_windows = sorted_spike_windows(filter_1,:);

        % if j==1
        %     par_save(base_aligned_sw_name,mutated_spike_windows);
        % end
        % even_more_local_config.stage_counter = 1;
        if even_more_local_config.has_ground_truth && even_more_local_config.debug_with_ground_truth && j~=1
            even_more_local_config = check_snr_of_spike_windows_with_table(even_more_local_config,mutated_spike_windows);
            even_more_local_config.stage_counter = even_more_local_config.stage_counter +1;
        end
        %put spike windows in the config
        even_more_local_config.mutated_spike_windows = mutated_spike_windows;


        %store the local tetrode
        even_more_local_config.tetrode = current_tetrode;


        %get the new size of raw after the filter
        new_raw_size = size(mutated_raw);

        %we will continue if the new filter didn't affect the size because that
        %means the filter did not filter anything out and thus running it will
        %result clustering the exact same data again which would be wasted
        %compute time
        if all(new_raw_size==raw_size_before) && j~=1
            % disp("No new data continuing ...")
            send(q,[]);
            continue;
        end
        if isempty(mutated_raw)
            send(q,[]);
            continue
        end
        % end




        raw_in_samples_format = spike_tetrode_dictionary_samples_format(current_tetrode);

        %repeat the same process with raw_in_samples_format
        mutated_raw_in_samples_format = raw_in_samples_format(:,:,filter_1);


        mean_of_relevant_channels =current_data{j,"sliced_channel_wise_means"};
        std_dvns_of_relevant_channels = current_data{j,"sliced_channel_stds"};

        wire_filter = find_live_wires(raw);
        % wire_filter = [1 2 3 4];
        nonzero_samples = mutated_raw_in_samples_format(:,wire_filter,:);
        minpeaks = shiftdim(min(max(nonzero_samples),[],2),2);
        maxvals = shiftdim(max(min(nonzero_samples),[],2),2);
        admax_val = 32767;
        good_spike_filter = minpeaks < admax_val & maxvals > (-admax_val);
        good_spike_idx = find(good_spike_filter);
        % good_spike_idx = 1:size(raw,2);

        timestamps_for_current_tetrode = timing_tetrode_dictionary(current_tetrode);
        mutated_ts_for_current_tetrode = timestamps_for_current_tetrode(filter_1,:);
        ir = calculate_input_range_for_raw_by_channel_ver_3(channels_in_current_tetrode,dir_with_channel_recordings);
        ir = ir.';

        %ir = ir(:,1) - ir(:,2);
        tvals = mean_of_relevant_channels + (std_dvns_of_relevant_channels * number_of_std_above_means) ;



        % config = spikesort_config(); %load the config file;


        try
            %OG [output,aligned,reg_timestamps,reg_timestamps_of_the_spikes] = run_spikesort_ntt_core_ver4(raw,timestamps_for_current_tetrode,good_spike_idx,ir,tvals,current_filename,config,channels_in_current_tetrode,i,sorted_spike_windows,initial_tetrodes_results_dir);
            local_tetrode_results_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(local_initial_tetrodes_results_dir);
            even_more_local_config.local_tetrode_results_dir = local_tetrode_results_dir;
            even_more_local_config.current_tetrode = current_tetrode;
            % even_more_local_config.raw_fp = raw_file_name;
            even_more_local_config.base_aligned_sw_name = base_aligned_sw_name;
            even_more_local_config.base_aligned_name = aligned_file_name;
            if ~isfile(even_more_local_config.base_aligned_name)
                [~,~,~,reg_timestamps_of_the_spikes,~,~,base_aligned_idxs] = run_spikesort_ntt_core_ver4(mutated_raw,mutated_ts_for_current_tetrode,good_spike_idx,ir,tvals,current_filename,even_more_local_config,channels_in_current_tetrode,mutated_spike_windows,local_tetrode_results_dir,current_tetrode);
            else
                if even_more_local_config.use_new_spike_detection
                    modded_base_aligned_idxs = base_aligned_idxs(filter_1);
                else
                    modded_base_aligned_idxs = base_aligned_idxs(abs(mutated_spike_windows(:,5)) > even_more_local_config.which_thresh);
                end
                [~,~,~,reg_timestamps_of_the_spikes] = run_spikesort_ntt_core_ver4(mutated_raw,mutated_ts_for_current_tetrode,good_spike_idx,ir,tvals,current_filename,even_more_local_config,channels_in_current_tetrode,mutated_spike_windows,local_tetrode_results_dir,current_tetrode,modded_base_aligned_idxs);
            end
            if  ~isempty(reg_timestamps_of_the_spikes)
                reg_timestamps_of_the_spikes = struct("reg_timestamps_of_the_spikes",reg_timestamps_of_the_spikes);
                par_save(reg_ts_of_spikes_file_name,reg_timestamps_of_the_spikes)


            else
                disp("Went into catch")
                send(q,[]);
                continue;
            end
        catch ME
            % end_time = toc(beginning_time);
            fprintf("\n")
            disp("########################################################################################")
            fprintf(2, "%s\n", getReport(ME, "extended", "hyperlinks", "off"));
            disp("########################################################################################")
            % fprintf('%s',ME.cause);
            send(q,[]);
            continue;
        end
        send(q,[]);
    end
end

end