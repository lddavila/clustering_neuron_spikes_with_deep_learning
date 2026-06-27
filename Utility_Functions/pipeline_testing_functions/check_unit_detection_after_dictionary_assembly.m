function [config] = check_unit_detection_after_dictionary_assembly(config,dictionaries_dir,ground_truth_cell_array,multipliers_in_mv)
finished_status_save_name = fullfile(config.dir_to_save_debug_files_to,"finished_after_dict_assembly_detection.txt");



if ~isfile(finished_status_save_name)
    table_of_best_rep = load(config.fp_to_table_of_best_rep);
    table_of_best_rep = table_of_best_rep.data_to_save;
    art_tetr_array = config.ART_TETR_ARRAY;
    table_of_available_dictionaries = struct2table(dir(fullfile(dictionaries_dir,"*sorted_spike_windows.mat")));
    table_of_available_dictionaries.name = string(table_of_available_dictionaries.name);
    table_of_available_dictionaries.folder = string(table_of_available_dictionaries.folder);

    flattened_multipliers = cell2mat(multipliers_in_mv);
    extended_table_of_best_rep_cell_array = cell(height(table_of_best_rep),1);
    tol_amount = 3; %equates to about .1 milliseconds

    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = height(table_of_best_rep);
    print_status_bar(num_iterations,"check_unit_detection_after_dictionary_assembly.m")

    % pre import all the dictionaries that you'll need as to avoid
    % excessive loading time

    cell_array_of_sorted_sw_dicts = cell(height(table_of_available_dictionaries),1);
    cell_array_of_spiking_channels = cell(height(table_of_available_dictionaries),1);

    folder_to_use =table_of_available_dictionaries{1,"folder"} ;
    table_of_available_dictionaries.tetr_num = str2double(strrep(strrep(table_of_available_dictionaries.name," sorted_spike_windows.mat",""),"t",""));
    table_of_available_dictionaries = sortrows(table_of_available_dictionaries,"tetr_num","ascend");
    % table_of_available_dictionaries(11:end,:) = [];
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = height(table_of_available_dictionaries);
    print_status_bar(num_iterations,"check_unit_detection_after_dictionary_assembly.m | loading sw dicts")
    parfor i=1:height(table_of_available_dictionaries)

        spike_windows_dict = load(fullfile(folder_to_use,"t"+string(table_of_available_dictionaries{i,"tetr_num"})+" sorted_spike_windows.mat"));
        spike_windows_dict = spike_windows_dict.data_to_save.sorted_spike_windows_for_current_tetrode_dictionary;
        cell_array_of_sorted_sw_dicts{i} = spike_windows_dict;
        spiking_channel_dict = load(fullfile(folder_to_use,"t"+string(table_of_available_dictionaries{i,"tetr_num"})+" spiking_channel_tetrode_dictionary.mat"));
        spiking_channel_dict = spiking_channel_dict.data_to_save.spiking_channel_tetrode_dictionary;
        cell_array_of_spiking_channels{i} = spiking_channel_dict;
        send(q,[]);
    end

    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = height(table_of_best_rep);
    print_status_bar(num_iterations,"check_unit_detection_after_dictionary_assembly.m | spike detection")
    if config.use_new_spike_detection
        thresholds_to_use = config.Multipliers;
    else
        thresholds_to_use = config.DEFAULT_CLUSTERING_Z_SCORES;
    end
    parfor i=1:height(table_of_best_rep)
        %since dictionaries are organized by tetrode for each row in table_of_best_rep
        %we must determine which tetrode contains the current best channel
        current_channel = table_of_best_rep{i,"all_channels"};
        [tetrodes_with_current_channel,~]= find(ismember(art_tetr_array,current_channel));
        if isempty(tetrodes_with_current_channel)
            send(q,[]);
            continue;
        end
        tetrode_names = strcat("t",string(tetrodes_with_current_channel));
        idx_of_current_multiplier_used = find(table_of_best_rep{i,"all_multiplier_idxs"} == thresholds_to_use);

        current_ground_truth_idxs = ground_truth_cell_array{table_of_best_rep{i,"unit"}};
        current_row = table_of_best_rep(i,:);
        edited_row = repelem(current_row,length(tetrode_names),1);
        edited_row.tetrode = tetrode_names;
        detection_ratio_after_dict_creation = zeros(length(tetrode_names),1);
        snr_ratio = zeros(length(tetrode_names),1);
        snr_raw = zeros(length(tetrode_names),1);
        if ~isempty(idx_of_current_multiplier_used)
            for j=1:length(tetrode_names)
                which_dict_index_to_use = find(table_of_available_dictionaries.tetr_num==tetrodes_with_current_channel(j));
                if isempty(which_dict_index_to_use)
                    continue;
                end
                spike_windows_dict = cell_array_of_sorted_sw_dicts{which_dict_index_to_use};

                sorted_spike_windows = spike_windows_dict(strrep(tetrode_names(j),".mat",""));

                spiking_channel_dict = cell_array_of_spiking_channels{which_dict_index_to_use};

                spiking_channels = cell2mat(spiking_channel_dict(strrep(tetrode_names(j),".mat","")).');

                %now that we know the multiplier used for the current row and the
                %channels in the current channel we can read multipliers in mv for
                %the appropriate thresholds per channel to use for each row of the
                %sorted spike windows
                if config.use_new_spike_detection
                    threshs_per_spike = flattened_multipliers(spiking_channels,idx_of_current_multiplier_used);
                else
                    threshs_per_spike = repelem(table_of_best_rep{i,"all_multiplier_idxs"},size(sorted_spike_windows,1),1);
                end
                %filter the spikes
                filtered_peak_locs = sorted_spike_windows(abs(sorted_spike_windows(:,5)) >= threshs_per_spike,4);
                
                is_tp = ismembertol(double(round(current_ground_truth_idxs)), double(round(filtered_peak_locs)),tol_amount,'DataScale',1);

                detection_ratio_after_dict_creation(j) = (sum(is_tp) / length(current_ground_truth_idxs))*100;
                snr_ratio(j) = detection_ratio_after_dict_creation(j) / ((sum(is_tp) /size(sorted_spike_windows,1) )*100);
                snr_raw(j) = (sum(is_tp)/size(sorted_spike_windows,1))*100;

            end
        end

        % edited_row.detection_ratio_after_dict_creation = detection_ratio_after_dict_creation;
        edited_row.("detection_ratio_stage_"+string(config.stage_counter)) = detection_ratio_after_dict_creation;
        edited_row.("raw_snr_stage_"+string(config.stage_counter)) = snr_raw;
        edited_row.("ratio_snr_stage_"+string(config.stage_counter)) = snr_ratio;
        extended_table_of_best_rep_cell_array{i} = edited_row;
        send(q,[]);
    end

    table_of_best_rep = [];
    for i=1:length(extended_table_of_best_rep_cell_array)
        if ~isempty(extended_table_of_best_rep_cell_array{i})
            table_of_best_rep = [table_of_best_rep;extended_table_of_best_rep_cell_array{i}];
        end
    end
    par_save(strrep(config.fp_to_table_of_best_rep,".mat","")+"_2.mat",table_of_best_rep);
    config.fp_to_table_of_best_rep = strrep(config.fp_to_table_of_best_rep,".mat","")+"_2.mat";
    file_id = fopen(fullfile(finished_status_save_name),"w");
    fclose(file_id);

else
    disp(finished_status_save_name +" already detected, skipping this step.")
    config.fp_to_table_of_best_rep = strrep(config.fp_to_table_of_best_rep,".mat","")+"_2.mat";
end
end