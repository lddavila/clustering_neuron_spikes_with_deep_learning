%% import the ground truth from recording 10
ground_truth = importdata("F:\10_600Neuron300SecondRecordingWithLevel10Noise\ground_truth\ground_truth.mat");

%% set the directory for the detected spikes
spikes_per_channel_dir = "F:\ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\spikes_per_channel min_mult 6";

%% import all the spikes per channel
table_of_all_spikes_per_channel = struct2table(dir(fullfile(spikes_per_channel_dir,"*.mat")));
table_of_all_spikes_per_channel.name = string(table_of_all_spikes_per_channel.name);
table_of_all_spikes_per_channel.folder = string(table_of_all_spikes_per_channel.folder);
spikes_per_channel = cell(height(table_of_all_spikes_per_channel),1);
for i=1:height(table_of_all_spikes_per_channel)
    spikes_per_channel{i} = importdata(fullfile(table_of_all_spikes_per_channel{i,"folder"},fullfile(table_of_all_spikes_per_channel{i,"name"})));
    disp("Finished "+string(i)+"/"+string(height(table_of_all_spikes_per_channel)))
end

%% import all the channel data
channel_dir = "F:\ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\filtered_data";
table_of_all_channels = struct2table(dir(fullfile(channel_dir,"*.mat")));
table_of_all_channels.name = string(table_of_all_channels.name);
table_of_all_channels.folder = string(table_of_all_channels.folder);
channel_data = cell(height(table_of_all_channels),1);
table_of_all_channels.channel_number = str2double(strrep(strrep(table_of_all_channels{:,"name"},"c",""),".mat",""));
table_of_all_channels = sortrows(table_of_all_channels,"channel_number");
parfor i=1:height(table_of_all_channels)
    channel_data{i} = importdata(fullfile(table_of_all_channels{i,"folder"},fullfile(table_of_all_channels{i,"name"})));
    disp("Finished "+string(i)+"/"+string(height(table_of_all_channels)))
end
%% import the thresholds per channel in microvolts
threshs_in_microvolts = importdata("F:\ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\mv_thresholds.mat");

%% now for every ground truth unit find how much of it appears on each channel given the threshold
%to determine this we need to understand all the possible permutations that
%we might have to check 
list_of_channels_to_try = 1:384;
list_of_units_to_try = 1:length(ground_truth);
list_of_thresholds_to_try = 1:size(threshs_in_microvolts{1},2);

% all_kinds_of_combinations = combinations(list_of_units_to_try,list_of_channels_to_try,list_of_thresholds_to_try);

%% put all the requried data into parallel constants to avoid any 
parallel_channel_data = parallel.pool.Constant(channel_data);
parallel_spikes_per_channel  = parallel.pool.Constant(spikes_per_channel);
parallel_thresholds_per_channel = parallel.pool.Constant(threshs_in_microvolts);
parallel_ground_truth = parallel.pool.Constant(ground_truth);
%% now run the parfor loop which will actually determine the unit detected ratio and mean amplitude of the unit per channel
tol_amount = 6;
% cell_array_of_tables_of_det_ratio = cell(height(table_of_all_channels),1);
dir_to_save_results = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"unit_to_channel_det_new"));
for i=1:height(table_of_all_channels)
    save_name = fullfile(dir_to_save_results,table_of_all_channels{i,"name"});
    if ~isfile(save_name)
        current_channel_data = importdata(fullfile(table_of_all_channels{i,"folder"},table_of_all_channels{i,"name"}));
        current_spikes_on_channel = importdata(fullfile(table_of_all_spikes_per_channel{i,"folder"},table_of_all_spikes_per_channel{i,"name"}));
        current_thresholds_for_channel = threshs_in_microvolts{i};
        peak_vals_on_channel = current_channel_data(current_spikes_on_channel);
        %get all possible combinations of unit and thresholds

        unit_and_thresh_combo_tables = combinations(list_of_units_to_try,current_thresholds_for_channel);
        q = parallel.pool.DataQueue;
        afterEach(q,@print_status_bar)
        num_iterations = height(unit_and_thresh_combo_tables);
        print_status_bar(num_iterations,"get_overlap_for_all_units_using_detected_spikes_in_pipeline.m")
        detect_ratio =nan(height(unit_and_thresh_combo_tables),1);
        avg_pk_amp = nan(height(unit_and_thresh_combo_tables),1);
        median_pk_amp = nan(height(unit_and_thresh_combo_tables),1);
        equivalent_peaks = cell(height(unit_and_thresh_combo_tables),1);

        parfor j=1:height(unit_and_thresh_combo_tables)
            filter_condition = peak_vals_on_channel>unit_and_thresh_combo_tables{j,"current_thresholds_for_channel"};
            filtered_peaks = current_spikes_on_channel(filter_condition);
            filtered_peak_amps = peak_vals_on_channel(filter_condition);
            ground_truth_idxs = ground_truth{unit_and_thresh_combo_tables{j,"list_of_units_to_try"}};

            [is_tp,loc_in_filtered_peaks]= ismembertol(double(round(ground_truth_idxs)), double(round(filtered_peaks)),tol_amount,'DataScale',1);

            avg_pk_amp(j) = mean(abs(filtered_peak_amps(loc_in_filtered_peaks(loc_in_filtered_peaks~=0))));
            median_pk_amp(j) = median(abs(filtered_peak_amps(loc_in_filtered_peaks(loc_in_filtered_peaks~=0))));
            detect_ratio(j) = (sum(is_tp) / numel(ground_truth_idxs))*100;
            %to avoid the misalignment caused by only keeping those not equal
            %to 0 we'll use an additional loop to create the data shape we want
            data_to_store_in_equivalent_peaks = nan(length(is_tp),1);
            for k=1:length(data_to_store_in_equivalent_peaks)
                if is_tp(k) && loc_in_filtered_peaks(k) ~= 0
                    data_to_store_in_equivalent_peaks(k) = filtered_peaks(loc_in_filtered_peaks(k));
                end
            end
            equivalent_peaks{j} = data_to_store_in_equivalent_peaks;

            send(q,[]);

        end
        unit_and_thresh_combo_tables.detect_ratio = detect_ratio;
        unit_and_thresh_combo_tables.mean_pk_amp = avg_pk_amp;
        unit_and_thresh_combo_tables.median_pk_amp = median_pk_amp;
        unit_and_thresh_combo_tables.equivalent_peaks = equivalent_peaks;
        unit_and_thresh_combo_tables.channel = repelem(str2double(strrep(strrep(table_of_all_channels{i,"name"},"c",""),".mat","")),height(unit_and_thresh_combo_tables),1);

        par_save(save_name,unit_and_thresh_combo_tables);
        % cell_array_of_tables_of_det_ratio{i} = unit_and_thresh_combo_tables;

    else
        % cell_array_of_tables_of_det_ratio{i} = importdata(save_name);
    end
    disp("Finished "+string(i)+"/"+string(height(table_of_all_channels)))
end


%% for each unit get the top 50 channels
%we do this cause the machine might not have enough memory for everything
table_of_all_channel_ratios = struct2table(dir(fullfile(dir_to_save_results,"*.mat")));
table_of_all_channel_ratios.name = string(table_of_all_channel_ratios.name);
table_of_all_channel_ratios.folder = string(table_of_all_channel_ratios.folder);
best_rep_cell_array = cell(height(table_of_all_channel_ratios),1);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = height(table_of_all_channel_ratios);
print_status_bar(num_iterations,"get_overlap_for_all_units_using_detected_spikes_in_pipeline.m")
parfor i=1:height(table_of_all_channel_ratios)

    try
        if isempty(best_rep_cell_array{i})
            current_table = importdata(fullfile(table_of_all_channel_ratios{i,"folder"},table_of_all_channel_ratios{i,"name"}));
            %for every ground truth unit select the top 10 rows

            best_per_unit = cell(length(list_of_units_to_try),1);
            for j=1:length(best_per_unit)
                select_condition = current_table{:,"list_of_units_to_try"}==list_of_units_to_try(j);
                only_current_unit = sortrows(current_table(select_condition,:),["detect_ratio","median_pk_amp","mean_pk_amp"],"descend");
                best_per_unit{j} = only_current_unit(1:10,:);
            end
            best_rep_cell_array{i} = vertcat(best_per_unit{:});
        end
    catch
    end
    send(q,[]);
    % disp("Finished "+string(i)+"/"+string(height(table_of_all_channel_ratios)))
end
%% concatenate all the results into single table
best_rep_table = vertcat(best_rep_cell_array{[1:100,102:length(best_rep_cell_array)]});
%% import the blind pass table
blind_pass_table = importdata("F:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\blind_pass_table.mat");

%% filter the blind pass table to only units that resulted in 80% accuracy or above
only_80 = blind_pass_table(blind_pass_table{:,"accuracy"}>80,:);
disp(only_80(:,["Tetrode","Cluster","accuracy","Max_Overlap_Unit","cluster_idx"]))

%% select relevant rows for the desired unit
desired_unit = 469;
rows_for_desired_unit = sortrows(best_rep_table(best_rep_table{:,"list_of_units_to_try"}==desired_unit,:),"detect_ratio");
disp(rows_for_desired_unit)

%% see if it's even the right channel number
disp(config.ART_TETR_ARRAY(list_of_channels_to_try))