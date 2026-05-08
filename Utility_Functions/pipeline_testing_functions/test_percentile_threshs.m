%% get a config file
config = spikesort_config();
config.Multipliers = 3:1:15;
default_array = config.ART_TETR_ARRAY;
% get the ground truth
config.ground_truth_cell_array = importdata("E:\10_600Neuron300SecondRecordingWithLevel10Noise\ground_truth\ground_truth.mat");
config.has_ground_truth = 1;
config.debug_with_ground_truth = 1;
config.GT_FP = "E:\10_600Neuron300SecondRecordingWithLevel10Noise\ground_truth\ground_truth.mat";

config.TIMESTAMP_FP = "E:\5_600Neuron300SecondRecordingWithLevel5Noise\timestamps\timestamps.mat";
description = "removed pcs from dimension selection & dropped spikes from bad dimensions & removed finalize clusters from pipeline";
dir_to_save_output_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path("E:\prc_5_test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise");
debug_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_output_to,"DEBUG"));
accuracy_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(debug_dir,"ACCURACY"));
% Open file for writing
fileID = fopen(fullfile(dir_to_save_output_to,'dir_description.txt'), 'w');
% Check if file opened successfully
if fileID == -1
   error('Failed to open file.');
end
% Write formatted data
fprintf(fileID, description+'\n');
% Close the file
fclose(fileID);
%% set the tetrode number you want to test
tetrode_numbers = [136,14,166,1,10,4,97,98,88,91];
tetrode_numbers = setdiff(1:size(config.ART_TETR_ARRAY,1),tetrode_numbers);
multipliers_to_test = [3 4 5 6 7 8 9 10];

config.fp_to_table_of_best_rep = "E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\table_of_best_rep_2.mat";
load("E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\mean_and_std\mean_and_std.mat","channel_wise_means","channel_wise_std")




increments_to_use = [5, 10, 15, 20, 25];
starting_percentiles = 90:-5:50;
ending_percentile = 5;
all_percentiles_to_use = [];
for j=1:length(starting_percentiles)
    starting_percentile = starting_percentiles(j);
    for i=1:length(increments_to_use)

        starting_point = starting_percentile;
        ending_point = max([0,starting_point - (3*increments_to_use(i))]);
        while ending_point > 0
            to_add = starting_point:(-1)*increments_to_use(i):ending_point;
            all_percentiles_to_use = [all_percentiles_to_use;to_add];
            starting_point = to_add(2);
            ending_point = max([0,starting_point - (3*increments_to_use(i))]);
        end


    end
end

all_percentiles_to_use = unique(all_percentiles_to_use,"rows",'stable');
for i=2:10%length(tetrode_numbers)
    which_tetrode = i;
    tetrode_number = 5;%tetrode_numbers(which_tetrode);
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
    for multiplier_to_test = multipliers_to_test
        config.which_thresh = multiplier_to_test;
        for percentile_counter=1:size(all_percentiles_to_use,1)
            local_config = config;
            local_config.percentiles_to_use = all_percentiles_to_use(percentile_counter,:);

            save_name = fullfile(accuracy_dir,"t"+string(tetrode_number)+"percentile_set"+string(percentile_counter)+"mult"+string(multiplier_to_test)+".mat");
            if ~isfile(save_name)
                local_config.ART_TETR_ARRAY = default_array(tetrode_number,:);



                channels_in_current_tetrode = local_config.ART_TETR_ARRAY;
                channels = channels_in_current_tetrode;

                local_initial_tetrodes_results_dir = fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"initial_pass_results min multiplier "+ string(multiplier_to_test));
                output_file_name = fullfile(local_initial_tetrodes_results_dir,current_tetrode+" output.mat");
                aligned_file_name = fullfile(local_initial_tetrodes_results_dir,current_tetrode+" aligned.mat");
                reg_ts_file_name= fullfile(local_initial_tetrodes_results_dir,current_tetrode+" reg_timestamps.mat");
                reg_ts_of_spikes_file_name =fullfile(local_initial_tetrodes_results_dir,current_tetrode+ " reg_timestamps_of_the_spikes.mat");
                peak_pcs_file_name = fullfile(local_initial_tetrodes_results_dir,current_tetrode+" peak_pcs.mat");

                %overwrite the field
                local_config.peak_pcs_file_name = peak_pcs_file_name;
                local_config.Multipliers_in_mv = importdata("E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\mv_thresholds.mat");

                % get the channel wise means and std

                % set the directory with the channel data
                dir_with_channel_recordings = "E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\filtered_data";

                %
                number_of_std_above_means = local_config.NUM_OF_STD_ABOVE_MEAN;
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
                for p=1:length(local_config.Multipliers_in_mv)
                    local_config.Multipliers_in_mv{p} = double(local_config.Multipliers_in_mv{p});
                end
                flat_multipliers = cell2mat(local_config.Multipliers_in_mv);
                per_channel_thresholds_for_curr_z_sc= flat_multipliers(:,find(local_config.Multipliers == multiplier_to_test));
                per_spike_thresholds = per_channel_thresholds_for_curr_z_sc(which_channel);

                mutated_raw = raw(:,max_peak_vals>=per_spike_thresholds,:);

                %filter the spike windows for debugging in clustering process
                mutated_spike_windows = sorted_spike_windows(max_peak_vals >= per_spike_thresholds,:);

                %put spike windows in the config
                local_config.mutated_spike_windows = mutated_spike_windows;

                %store the local tetrode
                local_config.tetrode = current_tetrode;


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
                local_config.current_table_of_best_rep = only_curent;
                %
                filenames = [];
                dir_to_save_spike_windows_to = "";
                local_config.dir_to_save_debug_files_to = debug_dir;
                % run the test
                disp("About to start clustering")
                local_config.plot_counter = 1;
                local_config.current_channels = channels;

                [output, aligned, reg_timestamps,reg_timestamps_of_the_spikes,peak_pcs,cluster_filters] = run_spikesort_ntt_core_ver4(mutated_raw, mutated_ts_for_current_tetrode, good_spike_idx, ir, tvals, filenames, local_config,channels,local_config.mutated_spike_windows,local_tetrode_results_dir,current_tetrode);
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
            blind_pass_table = table(repelem(multiplier_to_test,length(cell_array_of_cluster_ts),1),repelem("t"+string(tetrode_number),length(cell_array_of_cluster_ts),1),(1:length(cell_array_of_cluster_ts)).',cell_array_of_cluster_ts,cluster_filters,'VariableNames',["Multiplier","Tetrode","cluster","timestamps","cluster_idx"]);
            %calculate the accuracy for the clusters
            accuracy_array = zeros(length(cell_array_of_cluster_ts),1);
            blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,local_config,timestamps);
            blind_pass_table= add_accuracy_col(local_config,blind_pass_table);

            disp(blind_pass_table(:,["Multiplier","Tetrode","cluster","Max_Overlap_Unit","accuracy","Max_Overlap_perc_With_Unit","timestamps"]))
            data_struct = struct();
            data_struct.blind_pass_table = blind_pass_table;
            data_struct.prctile_used = local_config.percentiles_to_use;
            par_save(fullfile("E:\prc_2_test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY","t"+string(tetrode_number)+"_bp_table_and_struct_prc_count"+string(percentile_counter)+"_mult_"+string(multiplier_to_test)+".mat"),data_struct);
            disp("Finished saving the blind pass table")
            fprintf("Finished percentile set %i\n",percentile_counter);
        end
    end
end