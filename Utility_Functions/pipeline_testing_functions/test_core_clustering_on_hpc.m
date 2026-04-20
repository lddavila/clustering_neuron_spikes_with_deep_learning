function [] = test_core_clustering_on_hpc()
%% get a config file
config = spikesort_config();
config.Multipliers = 3:1:15;
default_array = config.ART_TETR_ARRAY;
% get the ground truth
config.ground_truth_cell_array = importdata("E:\10_600Neuron300SecondRecordingWithLevel10Noise\ground_truth\ground_truth.mat");
config.has_ground_truth = 1;
config.debug_with_ground_truth = 1;
config.GT_FP = "E:\10_600Neuron300SecondRecordingWithLevel10Noise\ground_truth\ground_truth.mat";
config.the_linspace_to_use = linspace(1,0,4);
config.TIMESTAMP_FP = "E:\5_600Neuron300SecondRecordingWithLevel5Noise\timestamps\timestamps.mat";
%% set the tetrode number you want to test
tetrode_numbers = [136,14,166,1,10,4,97,98,88,91];
multiplier_to_test = 3;
config.which_thresh = multiplier_to_test;
config.fp_to_table_of_best_rep = "E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\table_of_best_rep_2.mat";
% overwrite the art_tetrode array in the config
good_cluster_counter = 1;
tetrode_counter = 1;
config.the_linspace_to_use = linspace(1,0,4);
max_tries =5;
try_counter = 0;
while tetrode_counter < length(tetrode_numbers) 
    upper_bound_of_linspace = max(config.the_linspace_to_use);
    tetrode_number = tetrode_numbers(tetrode_counter);
    save_name = fullfile("E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY","t"+string(tetrode_number)+"upper_bound"+string(upper_bound_of_linspace)+".mat");
    if ~isfile(save_name) 
        config.ART_TETR_ARRAY = default_array(tetrode_number,:);


        % set some directories & variables that contain the necessary data for testing
        current_tetrode = "t"+string(tetrode_number);
        dictionaries_dir = "E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\dictionaries multiplier 3 num_dps 60";
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
        disp("Finished importing the data necessary for testing");
        channels_in_current_tetrode = config.ART_TETR_ARRAY;
        channels = channels_in_current_tetrode;

        local_initial_tetrodes_results_dir = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"initial_pass_results min multiplier "+ string(multiplier_to_test));
        output_file_name = fullfile(local_initial_tetrodes_results_dir,current_tetrode+" output.mat");
        aligned_file_name = fullfile(local_initial_tetrodes_results_dir,current_tetrode+" aligned.mat");
        reg_ts_file_name= fullfile(local_initial_tetrodes_results_dir,current_tetrode+" reg_timestamps.mat");
        reg_ts_of_spikes_file_name =fullfile(local_initial_tetrodes_results_dir,current_tetrode+ " reg_timestamps_of_the_spikes.mat");
        peak_pcs_file_name = fullfile(local_initial_tetrodes_results_dir,current_tetrode+" peak_pcs.mat");

        %overwrite the field
        config.peak_pcs_file_name = peak_pcs_file_name;
        config.Multipliers_in_mv = importdata("E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\mv_thresholds.mat");

        % get the channel wise means and std
        load("E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\mean_and_std\mean_and_std.mat","channel_wise_means","channel_wise_std")
        % set the directory with the channel data
        dir_with_channel_recordings = "E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\filtered_data";

        %
        number_of_std_above_means = config.NUM_OF_STD_ABOVE_MEAN;
        % do some interesting things
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
        for p=1:length(config.Multipliers_in_mv)
            config.Multipliers_in_mv{p} = double(config.Multipliers_in_mv{p});
        end
        flat_multipliers = cell2mat(config.Multipliers_in_mv);
        per_channel_thresholds_for_curr_z_sc= flat_multipliers(:,find(config.Multipliers == multiplier_to_test));
        per_spike_thresholds = per_channel_thresholds_for_curr_z_sc(which_channel);

        mutated_raw = raw(:,max_peak_vals>=per_spike_thresholds,:);

        %filter the spike windows for debugging in clustering process
        mutated_spike_windows = sorted_spike_windows(max_peak_vals >= per_spike_thresholds,:);

        %put spike windows in the config
        config.mutated_spike_windows = mutated_spike_windows;

        %store the local tetrode
        config.tetrode = current_tetrode;


        %get the new size of raw after the filter
        new_raw_size = size(mutated_raw);
        raw_in_samples_format = spike_tetrode_dictionary_samples_format(current_tetrode);

        %repeat the same process with raw_in_samples_format
        mutated_raw_in_samples_format = raw_in_samples_format(:,:,max_peak_vals>=per_spike_thresholds);


        mean_of_relevant_channels = channel_wise_means(channels_in_current_tetrode);
        std_dvns_of_relevant_channels = channel_wise_std(channels_in_current_tetrode);

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
        mutated_ts_for_current_tetrode = timestamps_for_current_tetrode(max_peak_vals>=per_spike_thresholds,:);
        ir = calculate_input_range_for_raw_by_channel_ver_3(channels_in_current_tetrode,dir_with_channel_recordings);
        ir = ir.';

        %ir = ir(:,1) - ir(:,2);
        tvals = mean_of_relevant_channels + (std_dvns_of_relevant_channels * number_of_std_above_means) ;



        % config = spikesort_config(); %load the config file;



        %OG [output,aligned,reg_timestamps,reg_timestamps_of_the_spikes] = run_spikesort_ntt_core_ver4(raw,timestamps_for_current_tetrode,good_spike_idx,ir,tvals,current_filename,config,channels_in_current_tetrode,i,sorted_spike_windows,initial_tetrodes_results_dir);
        local_tetrode_results_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(local_initial_tetrodes_results_dir);

        % import the table of best rep after dictionary creation
        table_of_best_rep_after_dictionary = importdata("E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\table_of_best_rep_2.mat");

        % filter table down to only current tetrode and multiplier
        c1 = table_of_best_rep_after_dictionary{:,"all_multiplier_idxs"}==multiplier_to_test;
        c2 = table_of_best_rep_after_dictionary{:,"tetrode"}==current_tetrode;
        only_curent = table_of_best_rep_after_dictionary(c1 & c2,:);
        config.current_table_of_best_rep = only_curent;
        %
        filenames = [];
        dir_to_save_spike_windows_to = "";
        config.dir_to_save_debug_files_to = "E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG";
        % run the test
        disp("About to start clustering")
        [output, aligned, reg_timestamps,reg_timestamps_of_the_spikes,peak_pcs,cluster_filters] = run_spikesort_ntt_core_ver4(mutated_raw, mutated_ts_for_current_tetrode, good_spike_idx, ir, tvals, filenames, config,channels,config.mutated_spike_windows,local_tetrode_results_dir,current_tetrode);
        disp("Finished clustering")
        %preserve the cluster ts for accuracy calculation phase
        cell_array_of_cluster_ts = cell(length(cluster_filters),1);
        for j=1:length(cell_array_of_cluster_ts)
            cell_array_of_cluster_ts{j} = reg_timestamps_of_the_spikes(cluster_filters{j});
        end
        par_save(save_name,cell_array_of_cluster_ts);
    else
        cell_array_of_cluster_ts = importdata(save_name);
    end
    disp("Finished getting cell_array_of_cluster_ts")
    %create a pseudo blind pass table which can be used to compute accuracy
    blind_pass_table = table(repelem(multiplier_to_test,length(cell_array_of_cluster_ts),1),repelem("t"+string(tetrode_number),length(cell_array_of_cluster_ts),1),(1:length(cell_array_of_cluster_ts)).',cell_array_of_cluster_ts,'VariableNames',["Multiplier","Tetrode","cluster","timestamps"]);
    %calculate the accuracy for the clusters
    accuracy_array = zeros(length(cell_array_of_cluster_ts),1);
    blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,config,timestamps);
    blind_pass_table= add_accuracy_col(config,blind_pass_table);

    disp(blind_pass_table(:,["Multiplier","Tetrode","cluster","Max_Overlap_Unit","accuracy"]))
    data_struct = struct();
    data_struct.blind_pass_table = blind_pass_table;
    data_struct.linspace_used = config.the_linspace_to_use;
    par_save(fullfile("E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY","t"+string(tetrode_number)+"_bp_table_and_struct"+string(upper_bound_of_linspace)+".mat"),data_struct);
    disp("Finished saving the blind pass table")
    if any(blind_pass_table{:,"accuracy"} > 80)
        %if you succeed then try the next tetrode starting over with the
        %same parameters
        tetrode_counter = tetrode_counter+1;
        good_cluster_counter = good_cluster_counter+ sum(blind_pass_table{:,"accuracy"} > 80,'all');
        config.the_linspace_to_use = linspace(1,0,4);
        disp("Got good cluster, recording and moving to next tetrode")
    elseif try_counter >= max_tries
        %if you max out your number of attemps then reset the space and
        %begin next tetrode
        tetrode_counter = tetrode_counter+1;
        try_counter = 0;
        config.the_linspace_to_use = linspace(1,0,4);
        disp("Used up all tries, proceeding to next tetrode")
    else
        %if you fail, but still have attempts left, then readjust the space
        %and try clustering again
        config.the_linspace_to_use = linspace(upper_bound_of_linspace-.1,0,4);
        try_counter = try_counter+1;
        disp("Failed to get a cluster above 80% accuracy, adjusting linspace")
    end
    fprintf("Finished tetrode t%i upper bound of linspace %.2f\n",tetrode_number,upper_bound_of_linspace);

end
end