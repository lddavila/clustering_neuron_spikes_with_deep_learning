function [] = check_ground_truth_appearence_per_channel(ground_truth_cell_array,multipliers_in_mv,ordered_list_of_channels,pk_locs_cell_array,pk_vals_cell_array,config)
cell_array_of_best_channels_per_unit = cell(length(ground_truth_cell_array),1);
tol_amount = 6; %equivalent to .2 milliseconds, can be adjusted to be more/less strict
if ~isfile(fullfile(config.dir_to_save_debug_files_to,'finished_finding_best_channel_per_unit.txt'))
    for i=1:length(ground_truth_cell_array)
        current_ground_truth = ground_truth_cell_array{i};
        all_channels = 1:length(ordered_list_of_channels);
        all_multiplier_idxs = 1:length(multipliers_in_mv{1});
        all_combinations_of_mult_and_channels = combinations(all_channels,all_multiplier_idxs);
        all_combinations_of_mult_and_channels.unit = repelem(i,height(all_combinations_of_mult_and_channels),1);
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
            %filter out any rows with nans
            all_combinations_of_mult_and_channels(isnan(all_combinations_of_mult_and_channels{:,"mean_amplitude"}),:) = [];
            par_save(save_name,all_combinations_of_mult_and_channels)
        else
            all_combinations_of_mult_and_channels = importdata(save_name);
            all_combinations_of_mult_and_channels.unit = repelem(i,height(all_combinations_of_mult_and_channels),1);
            all_combinations_of_mult_and_channels(isnan(all_combinations_of_mult_and_channels{:,"mean_amplitude"}),:) = [];
            par_save(save_name,all_combinations_of_mult_and_channels)
        end
        all_channels_in_sorted_order = unique(all_combinations_of_mult_and_channels{:,"all_channels"},'stable');
        if ~isempty(all_channels_in_sorted_order)
            top_4_channels_for_current_unit = all_channels_in_sorted_order(1:min([3,length(all_channels_in_sorted_order)]));
            selection_cond = ismember(all_combinations_of_mult_and_channels{:,"all_channels"},top_4_channels_for_current_unit);
            cell_array_of_best_channels_per_unit{i} = all_combinations_of_mult_and_channels(selection_cond,:);
        else
            cell_array_of_best_channels_per_unit{i} = cell2table(cell(0,length(all_combinations_of_mult_and_channels.Properties.VariableNames)),'VariableNames',string(all_combinations_of_mult_and_channels.Properties.VariableNames))
        end
        
        
        disp('Finished '+string(i));
    end
    table_of_best_rep = vertcat(cell_array_of_best_channels_per_unit{:});
    par_save(fullfile(config.dir_to_save_debug_files_to,"table_of_best_rep.mat"),table_of_best_rep)
    fileID = fopen(fullfile(config.dir_to_save_debug_files_to,'finished_finding_best_channel_per_unit.txt'),'w');
    fclose(fileID);

end

end
