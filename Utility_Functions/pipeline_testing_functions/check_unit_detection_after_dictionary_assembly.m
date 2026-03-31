function [] = check_unit_detection_after_dictionary_assembly(config,dictionaries_dir,ground_truth_cell_array,multipliers_in_mv)
finished_status_save_name = fullfile(config.dir_to_save_debug_files_to,"finished_after_dict_assembly_detection.txt");



if ~isfile(finished_status_save_name)
    table_of_best_rep = importdata(config.fp_to_table_of_best_rep);
    art_tetr_array = config.ART_TETR_ARRAY;
    table_of_available_dictionaries = struct2table(dir(fullfile(dictionaries_dir,"*sorted_spike_windows.mat")));
    table_of_available_dictionaries.name = string(table_of_available_dictionaries.name);
    table_of_available_dictionaries.folder = string(table_of_available_dictionaries.folder);

    flattened_multipliers = cell2mat(multipliers_in_mv);
    extended_table_of_best_rep_cell_array = cell(height(table_of_best_rep),1);
    tol_amount = 6; %equates to about .2 milliseconds

    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = height(table_of_best_rep);
    print_status_bar(num_iterations,"check_unit_detection_after_dictionary_assembly.m")

    % pre import all the dictionaries that you'll need as to avoid
    % excessive loading time

    cell_array_of_sorted_sw_dicts = cell(height(table_of_available_dictionaries),1);
    cell_array_of_spiking_channels = cell(height(table_of_available_dictionaries),1);
    for i=1:height(table_of_available_dictionaries)
        spike_windows_dict = importdata(fullfile(table_of_available_dictionaries{i,"folder"},"t"+string(i)+" sorted_spike_windows.mat"));
        spike_windows_dict = spike_windows_dict.sorted_spike_windows_for_current_tetrode_dictionary;
        cell_array_of_sorted_sw_dicts{i} = spike_windows_dict;
        spiking_channel_dict = importdata(fullfile(table_of_available_dictionaries{1,"folder"},"t"+string(i)+" spiking_channel_tetrode_dictionary.mat"));
        spiking_channel_dict = spiking_channel_dict.spiking_channel_tetrode_dictionary;
        cell_array_of_spiking_channels{i} = spiking_channel_dict;
    end
    for i=1:height(table_of_best_rep)
        %since dictionaries are organized by tetrode for each row in table_of_best_rep
        %we must determine which tetrode contains the current best channel
        current_channel = table_of_best_rep{i,"all_channels"};
        [tetrodes_with_current_channel,~]= find(ismember(art_tetr_array,current_channel));
        tetrode_names = strcat("t",string(tetrodes_with_current_channel));
        current_multiplier_used = table_of_best_rep{i,"all_multiplier_idxs"} - (min(config.Multipliers)-1);
        current_ground_truth_idxs = ground_truth_cell_array{table_of_best_rep{i,"unit"}};
        current_row = table_of_best_rep(i,:);
        edited_row = repelem(current_row,length(tetrode_names),1);
        edited_row.tetrode = tetrode_names;
        detection_ratio_after_dict_creation = zeros(length(tetrode_names),1);
        for j=1:length(tetrode_names)
            spike_windows_dict = cell_array_of_sorted_sw_dicts{tetrodes_with_current_channel(j)};
            
            sorted_spike_windows = spike_windows_dict(strrep(tetrode_names(j),".mat",""));

            spiking_channel_dict = cell_array_of_spiking_channels{tetrodes_with_current_channel(j)};

            spiking_channels = cell2mat(spiking_channel_dict(strrep(tetrode_names(j),".mat","")).');

            %now that we know the multiplier used for the current row and the
            %channels in the current channel we can read multipliers in mv for
            %the appropriate thresholds per channel to use for each row of the
            %sorted spike windows
            threshs_per_spike = flattened_multipliers(spiking_channels,current_multiplier_used);

            %filter the spikes
            filtered_peak_locs = sorted_spike_windows(abs(sorted_spike_windows(:,5)) >= threshs_per_spike,4);


            detection_ratio_after_dict_creation(j) = (sum(ismembertol(double(round(current_ground_truth_idxs)), double(round(filtered_peak_locs)),tol_amount,'DataScale',1)) / length(current_ground_truth_idxs))*100;
        end
        edited_row.detection_ratio_after_dict_creation = detection_ratio_after_dict_creation;
        extended_table_of_best_rep_cell_array{i} = edited_row;
        send(q,[]);
    end
    table_of_best_rep = vertcat(extended_table_of_best_rep_cell_array{:});
    par_save(config.fp_to_table_of_best_rep,table_of_best_rep);
    file_id = fopen(fullfile(finished_status_save_name),"w");
    fclose(file_id);
    
else
    disp(finished_status_save_name +" already detected, skipping this step.")
end
end