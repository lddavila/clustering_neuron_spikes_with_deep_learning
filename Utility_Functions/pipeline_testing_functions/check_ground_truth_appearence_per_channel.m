function [] = check_ground_truth_appearence_per_channel(ground_truth_cell_array,multipliers_in_mv,ordered_list_of_channels,pk_locs_cell_array,pk_vals_cell_array,config)

if ~isfile('finished_finding_best_channel_per_unit.txt')
    for i=1:height(ground_truth_cell_array)
        current_ground_truth = ground_truth_cell_array{i};
        all_combinations_of_mult_and_channels = combinations(ordered_list_of_channels,1:length(multipliers_in_mv{1}));
        detection_ratio = zeros(height(all_combinations_of_mult_and_channels),1);
        mean_amplitude_of_detected_spikes = zeros(height(all_combinations_of_mult_and_channels),1);
        multiplier_in_mv_col = zeros(height(all_combinations_of_mult_and_channels),1);
        median_amplitude_of_detected_spikes = zeros(height(all_combinations_of_mult_and_channels),1);
        q = parallel.pool.DataQueue;
        afterEach(q,@print_status_bar)
        num_iterations = height(all_combinations_of_mult_and_channels);
        print_status_bar(num_iterations,"check_ground_truth_appearences_per_channel.m")
        save_name =fullfile(config.dir_to_save_debug_files_to,"Unit_"+string(i)+".mat") ;
        if ~isfile(save_name)
            parfor j=1:height(all_combinations_of_mult_and_channels)
                current_channel_peak_locs = pk_locs_cell_array{all_combinations_of_mult_and_channels{j,"all_channels"}};
                current_channel_peak_amps = pk_vals_cell_array{all_combinations_of_mult_and_channels{j,"all_channels"}};
                current_channel_thresholds_in_mv = multipliers_in_mv{all_combinations_of_mult_and_channels{j,"all_channels"}};
                current_channel_threshold_level = current_channel_thresholds_in_mv(all_combinations_of_mult_and_channels{j,"all_multiplier_idxs"});

                filtered_peak_locs = current_channel_peak_locs(abs(current_channel_peak_amps) >= abs(current_channel_threshold_level));
                filtered_peak_amps = current_channel_peak_amps(abs(current_channel_peak_amps) >= abs(current_channel_threshold_level));
                [is_tp,loc_in_filtered_peaks]= ismembertol(double(round(current_ground_truth)), double(round(filtered_peak_locs)),tol_amount,'DataScale',1);
                detection_ratio(j) = (sum(is_tp) / length(current_ground_truth)) * 100;
                mean_amplitude_of_detected_spikes(j) = mean(abs(filtered_peak_amps(loc_in_filtered_peaks(loc_in_filtered_peaks~=0))));
                multiplier_in_mv_col(j) = current_channel_threshold_level;
                median_amplitude_of_detected_spikes(j) = median(abs(filtered_peak_amps(loc_in_filtered_peaks(loc_in_filtered_peaks~=0))));
                send(q,[]);
            end

            all_combinations_of_mult_and_channels.detection_ratio = detection_ratio;
            all_combinations_of_mult_and_channels.mult_in_mv = multiplier_in_mv_col;
            all_combinations_of_mult_and_channels.mean_amplitude = mean_amplitude_of_detected_spikes;
            all_combinations_of_mult_and_channels.median_amp = median_amplitude_of_detected_spikes;

            all_combinations_of_mult_and_channels = sortrows(all_combinations_of_mult_and_channels,["detection_ratio","mean_amplitude"],"descend");

            par_save(save_name,all_combinations_of_mult_and_channels)


        end
        disp('Finished '+string(i));
    end
end
fileID = fopen('finished_finding_best_channel_per_unit.txt','w');
fclose(fileID);
end