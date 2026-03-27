%% set the path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%% specify some tetrodes to test
tetrodes_to_test = ["t13","t136","t14","t166","t176","t179","t274","t282","t4","t61"];
tetrode_rows = str2double(strrep(tetrodes_to_test,"t",""));

%% import the bp table
blind_pass_table = importdata("F:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\blind_pass_table.mat");

%% filter down to only good examples
only_80 = blind_pass_table(blind_pass_table{:,"accuracy"}>80,:);

%% impor the ground truth data
ground_truth = importdata("F:\10_600Neuron300SecondRecordingWithLevel10Noise\ground_truth\ground_truth.mat");

%% get all the ground truth units for the good examples
gt_to_use = unique(only_80{:,"Max_Overlap_Unit"});
%% get a config file
config = spikesort_config();

%% overwrite the config to only use the specified rows
config.ART_TETR_ARRAY(setdiff(1:size(config.ART_TETR_ARRAY),tetrode_rows),:) = 0;

%% set some parameters on the config
config.RECORDING_NAME = "10_600Neuron300SecondRecordingWithLevel10Noise";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"test_ic_"+config.RECORDING_NAME);
config.BLIND_PASS_DIR_PRECOMPUTED_ONLY_END = "test_ic_"+config.RECORDING_NAME;
disp("Recording Name");
disp(config.RECORDING_NAME)
startup;


ext_drive_fp = "F:";
config.GT_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"ground_truth","ground_truth.mat");
config.TIMESTAMP_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(ext_drive_fp,config.RECORDING_NAME,"recordings_by_channel");
% config.ART_TETR_ARRAY = config.ART_TETR_ARRAY(1,:);
config.BLIND_PASS_DIR_PRECOMPUTED = strrep(config.BLIND_PASS_DIR_PRECOMPUTED,fullfile(config.base_file_path,"Default_Results_Dir"),"F:");



%% run the first step of the pipeline 
%run_entire_clustering_algorithm_ver_2(config);
scale_factor = config.SCALE_FACTOR;
dir_with_channel_recordings = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
num_dps = config.NUM_DPTS_TO_SLICE;

if config.use_new_spike_detection
    z_score_or_multiplier = "Multiplier";
else
    z_score_or_multiplier = "Z Score";
end
%create the directory for the template files
create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"Shape_Template_PNGs"));

%% load the timestamps into memory
timestamps = importdata(config.TIMESTAMP_FP);
disp("Finished Importing timestamps for recording")

%% read the precomputed dir from the config
precomputed_dir = config.BLIND_PASS_DIR_PRECOMPUTED;
disp("Finished setting the blind pass directory")

%% get the ordered list of channels
ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);

%% remove any channels that we set equal to 0
nonzero_channels = unique(config.ART_TETR_ARRAY);
nonzero_channels = strcat("c",string(setdiff(nonzero_channels,0)),".mat");
ordered_list_of_channels = nonzero_channels;

%% Get the Min Threshold
min_threshold = config.NUM_OF_STD_ABOVE_MEAN;

%% filter the data
dir_to_store_filtered_data = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"filtered_data"));
apply_filter(ordered_list_of_channels,config,dir_to_store_filtered_data,dir_with_channel_recordings)

%overwrite the channel directory with your filtered data
dir_with_channel_recordings = dir_to_store_filtered_data;

%% plot the filtered and unfiltered channels
unique_channels = unique(config.ART_TETR_ARRAY(tetrode_rows));
for i=1:length(unique_channels)
    figure;
    tiledlayout(1,2);
    nexttile();
    current_channel = unique_channels(i);
    channel_data = importdata(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS,"c"+string(current_channel)+".mat"));
    plot(channel_data(1:1000));
    title("Unfiltered")
    % hold on; 

    nexttile();
    current_channel = unique_channels(i);
    channel_data = importdata(fullfile(dir_to_store_filtered_data,"c"+string(current_channel)+".mat"));
    plot(channel_data(1:1000));
    title("Filtered");
    sgtitle("Channel "+string(current_channel));
    % hold on; 
end

%% find the max detection channel for each unit
% for AF STAGE 1 AFTER SPIKE DETECTION
clc;
max_detection_channel = repelem("",length(gt_to_use),1);
detection_level = zeros(length(gt_to_use),1);
tetrodes_that_contain_that_channel =cell(length(gt_to_use),1);
the_mean_amp_of_detected_spikes = nan(length(gt_to_use),1);
for i=1:length(max_detection_channel)
    current_ground_truth_idxs = ground_truth{gt_to_use(i)};
    for j=1:height(table_of_all_spikes_per_channel)
        current_spikes_per_channel = table_of_all_spikes_per_channel{j,"spikes_per_channel"}{1};
        channel_data = importdata(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS,table_of_all_spikes_per_channel{j,"name"}));
        [is_in,where_it_is_in_table_of_all_spikes_per_channel] = ismembertol(double(current_ground_truth_idxs),current_spikes_per_channel,6,'DataScale',1);
        detection_level_for_current_channel = sum(is_in)/length(current_ground_truth_idxs) * 100;
        if detection_level(i) < detection_level_for_current_channel
            detection_level(i) = detection_level_for_current_channel;
            max_detection_channel(i) = table_of_all_spikes_per_channel{j,"name"};
            tetrodes_that_contain_that_channel{i} = strcat("t",string(find(any(ismember(config.ART_TETR_ARRAY,str2double(strrep(strrep(table_of_all_spikes_per_channel{j,"name"},"c",""),".mat",""))),2))));
            the_mean_amp_of_detected_spikes(i) = mean(abs(channel_data(current_spikes_per_channel(where_it_is_in_table_of_all_spikes_per_channel(where_it_is_in_table_of_all_spikes_per_channel~=0)))));
        end
    end
end
disp("Stage 1");
disp([gt_to_use,max_detection_channel,detection_level,the_mean_amp_of_detected_spikes]);
disp(tetrodes_that_contain_that_channel)
for i=1:length(gt_to_use)
    current_tetrodes = tetrodes_that_contain_that_channel{i};
    has_tetrode_condition = contains(only_80{:,"Tetrode"},current_tetrodes);
    disp("Expected Max Overlap unit to see");
    disp(gt_to_use(i));
    disp("Detection Ratio");
    disp(detection_level(i));
    disp("Max Detection channel");
    disp(max_detection_channel(i));
    disp(only_80(has_tetrode_condition,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy"]));
    
end
%% plot all the found peaks for channel and the nearest unit 
close all;
plotting_window = 100;
for i=33:height(table_of_all_spikes_per_channel)
    current_channel_data = importdata(fullfile(dir_with_channel_recordings,table_of_all_spikes_per_channel{i,"name"}));
    current_spikes = table_of_all_spikes_per_channel{i,"spikes_per_channel"}{1};
    for k=1:length(current_spikes)
        f = figure;
        window_beginning = current_spikes(k)-plotting_window;
        window_end = current_spikes(k)+plotting_window;
        x_data = window_beginning:window_end;
        y_data = current_channel_data(window_beginning:window_end);
        plot(x_data.',y_data);
        hold on;
        found_x = current_spikes(k);
        found_y = current_channel_data(found_x);
        scatter(found_x,found_y,20,'red','filled');
        hold on;
        legend_string = ["channel_data","Detected Spike",repelem("",1,length(gt_to_use))];
        has_at_least_one = false;
        size_to_use = 100;
        for j=1:length(gt_to_use)
            current_gt_idxs = ground_truth{gt_to_use(j)};
            in_bound = current_gt_idxs <= window_end & current_gt_idxs >= window_beginning;
            legend_string(j+2) = "Neuron "+string(gt_to_use(j))+" ground truth";
            gt_x = current_gt_idxs(in_bound);
            gt_y = current_channel_data(gt_x);

            if ~isempty(gt_x)
                disp("got here")
            end
            if isempty(gt_x) && isempty(gt_y) && ~has_at_least_one
                continue;
            else
                has_at_least_one = true;
            end
            try
                scatter(gt_x,gt_y,size_to_use,'filled');
                size_to_use = size_to_use -10;
                hold on;
            catch
                close(f)
                continue;
            end

        end
        if ~has_at_least_one
            close(f)
            continue;
        end
        
        legend(legend_string);
        title(table_of_all_spikes_per_channel{i,"name"});
        try
            close(f)
        catch
        end
    end
end

%%
what_is_computed = ["",""];
if ~isfolder(fullfile(precomputed_dir,"z_score")) %means that the z_score folder is already computed and we will skip computing it again
    z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"z_score")); %not yet computed
else
    z_score_dir = fullfile(precomputed_dir,"z_score");
end
disp("Finished Creating Z Score Directory");
beginning_time = tic;
[channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,dir_with_channel_recordings,z_score_dir,scale_factor,config,what_is_computed); %will get the mean and std of every channel and calculate z_score for data set if not yet created
mean_and_std_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"mean_and_std"));
save(fullfile(mean_and_std_dir,"mean_and_std.mat"),"channel_wise_means","channel_wise_std");

%% run spike detection
config.ALREADY_DONE_FILES = [""];
lowest_bound_spikes_per_channel_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spikes_per_channel min_mult "+string(min(config.Multipliers))));
multipliers_in_mv = use_ic_spike_det(lowest_bound_spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,scale_factor,config,config.Multipliers);
config.Multipliers_in_mv = multipliers_in_mv;

%% calculate the spike detection success for the ground truth units we expect to see
table_of_all_spikes_per_channel = struct2table(dir(fullfile(lowest_bound_spikes_per_channel_dir,"*.mat")));
table_of_all_spikes_per_channel.name = string(table_of_all_spikes_per_channel.name);
table_of_all_spikes_per_channel.folder = string(table_of_all_spikes_per_channel.folder);
spikes_per_channel = cell(height(table_of_all_spikes_per_channel),1);
for i=1:height(table_of_all_spikes_per_channel)
    spikes_per_channel{i} = importdata(fullfile(table_of_all_spikes_per_channel{i,"folder"},fullfile(table_of_all_spikes_per_channel{i,"name"})));
    disp("Finished "+string(i)+"/"+string(height(table_of_all_spikes_per_channel)))
end
table_of_all_spikes_per_channel.spikes_per_channel = spikes_per_channel;
%% import the channel dir 
channel_dir = "F:\test_ic_10_600Neuron300SecondRecordingWithLevel10Noise\filtered_data";
table_of_all_channels = struct2table(dir(fullfile(channel_dir,"*.mat")));
table_of_all_channels.name = string(table_of_all_channels.name);
table_of_all_channels.folder = string(table_of_all_channels.folder);
channel_data = cell(config.max_channel_number,1);
table_of_all_channels.channel_number = str2double(strrep(strrep(table_of_all_channels{:,"name"},"c",""),".mat",""));
table_of_all_channels = sortrows(table_of_all_channels,"channel_number");
parfor i=1:height(table_of_all_channels)
    channel_data{i} = importdata(fullfile(table_of_all_channels{i,"folder"},fullfile(table_of_all_channels{i,"name"})));
    disp("Finished "+string(i)+"/"+string(height(table_of_all_channels)))
end
threshs_in_microvolts = importdata("F:\test_ic_10_600Neuron300SecondRecordingWithLevel10Noise\mv_thresholds.mat");
list_of_channels_to_try = table_of_all_channels.channel_number;
list_of_units_to_try = gt_to_use;
list_of_thresholds_to_try = 1:size(threshs_in_microvolts{1},2);

% now run the parfor loop which will actually determine the unit detected ratio and mean amplitude of the unit per channel
tol_amount = 6;
%% cell_array_of_tables_of_det_ratio = cell(height(table_of_all_channels),1);
dir_to_save_results = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile("F:","first_part_of_the_pipeline"));
for i=1:height(table_of_all_channels)
    save_name = fullfile(dir_to_save_results,table_of_all_channels{i,"name"});
    if ~isfile(save_name)
        current_channel_data = importdata(fullfile(table_of_all_channels{i,"folder"},table_of_all_channels{i,"name"}));
        current_spikes_on_channel = importdata(fullfile(table_of_all_spikes_per_channel{i,"folder"},table_of_all_spikes_per_channel{i,"name"}));
        current_thresholds_for_channel = threshs_in_microvolts{table_of_all_channels{i,"channel_number"}};
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
best_rep_table = vertcat(best_rep_cell_array{:});
%%
%depending on the method we will either filter spikes by their z score or
%by the thresholds returned by use_ic_spike_det
if ~config.use_new_spike_detection
    thresholds_to_check = config.DEFAULT_CLUSTERING_Z_SCORES;
    thresholds_to_check = sort(thresholds_to_check,'ascend');
else
    thresholds_to_check = 1:length(config.Multipliers);
end
lowest_bound_threshold = min(thresholds_to_check);

lowest_bound_spike_windows_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spike_windows min_z_score " + string(lowest_bound_threshold) + " num dps "+ string(num_dps)));
get_lowest_bound_spike_windows(ordered_list_of_channels,lowest_bound_spikes_per_channel_dir,lowest_bound_threshold,num_dps,z_score_dir,lowest_bound_spike_windows_dir,config)

%% import all the spike windows files and make sure that they align with stage 1
% for AF
spike_windows_table = struct2table(dir(fullfile(lowest_bound_spike_windows_dir,"*.mat")));
spike_windows_table.folder = string(spike_windows_table.folder);
spike_windows_table.name = string(spike_windows_table.name);
spike_windows_cell_array = cell(height(spike_windows_table),1);
stage_2_detection_levels = zeros(length(detection_level),1);
for i=1:height(spike_windows_table)
    spike_windows_cell_array{i} = importdata(fullfile(spike_windows_table{i,"folder"},spike_windows_table{i,"name"}));
    if size(spike_windows_cell_array{i},1) ~= length(table_of_all_spikes_per_channel{i,"spikes_per_channel"}{1})
        disp("data loss occured")
    end
    %find which unit had the current channel as it's max detection channel
    gt_to_use_for_this = find(max_detection_channel==spike_windows_table{i,"name"});
    gt_unit_to_use_for_this = gt_to_use(gt_to_use_for_this);
    try
        current_ground_truth_idxs = ground_truth{gt_unit_to_use_for_this};
        detection_level_for_current_channel = sum(ismembertol(double(current_ground_truth_idxs),table_of_all_spikes_per_channel{i,"spikes_per_channel"}{1},6,'DataScale',1))/length(current_ground_truth_idxs) * 100;
        stage_2_detection_levels(gt_to_use_for_this) = detection_level_for_current_channel;
    catch
    end
end
disp([gt_to_use,max_detection_channel,detection_level,stage_2_detection_levels])
%%
art_tetr_array = config.ART_TETR_ARRAY;
if ~config.use_new_spike_detection
    dictionaries_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"dictionaries min_z_score "+string(config.DEFAULT_CLUSTERING_Z_SCORES(1))+ " num_dps "+string(num_dps)));
else
    dictionaries_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"dictionaries multiplier "+string(config.Multipliers(1))+ " num_dps "+string(num_dps)));
end
% disp("the dictionaries dir")
% disp(dictionaries_dir)
min_threshold = config.NUM_OF_STD_ABOVE_MEAN;
get_dictionaries_of_all_spikes_ver_3(art_tetr_array,lowest_bound_spike_windows_dir,dir_with_channel_recordings,timestamps,num_dps,scale_factor,dictionaries_dir,config,min_threshold);


%% FOR AF
% check each dictionary to make sure the detection hold on
table_of_all_sorted_sw_dictionaries = struct2table(dir(fullfile(dictionaries_dir,"*sorted_spike_windows*.mat")));
table_of_all_sorted_sw_dictionaries.folder = string(table_of_all_sorted_sw_dictionaries.folder);
table_of_all_sorted_sw_dictionaries.name = string(table_of_all_sorted_sw_dictionaries.name);
stage_3_detection_levels = zeros(length(gt_to_use),1);
unique_tetrode_by_channel_list = ["t274","t166","t176","t136","t13","t14","t4","t61","t282"];
for i=1:length(unique_tetrode_by_channel_list)
    current_spike_windows_dictionary = importdata(fullfile(table_of_all_sorted_sw_dictionaries{i,"folder"},unique_tetrode_by_channel_list(i)+" sorted_spike_windows.mat"));
    current_spike_windows_dictionary = current_spike_windows_dictionary.sorted_spike_windows_for_current_tetrode_dictionary;
    sorted_spike_windows = current_spike_windows_dictionary(string(keys(current_spike_windows_dictionary)));

    just_the_tetrode = split(table_of_all_sorted_sw_dictionaries{i,"name"});
    just_the_tetrode = just_the_tetrode(1);
    %spike windows is by channel
    %dictionaries are arranged by tetrode
    channels_dictionary = importdata(fullfile(table_of_all_dictionaries{i,"folder"},just_the_tetrode+" tetrode_dictionary.mat"));
    channels_dictionary = channels_dictionary.tetrode_dictionary;
    channels_for_tetrode = strcat("c",string(channels_dictionary(string(keys(channels_dictionary)))),".mat");

    rows_where_they_exist = table_of_all_spikes_per_channel{ismember(table_of_all_spikes_per_channel{:,"name"},channels_for_tetrode),"spikes_per_channel"};
    size_of_rows = size(vertcat(rows_where_they_exist{:}),1);
    if size_of_rows < size(sorted_spike_windows,1)
        disp("data loss occured")
    end
    gt_unit_to_use_for_this = gt_to_use(i);
    try
        current_ground_truth_idxs = ground_truth{gt_unit_to_use_for_this};
        spike_idxs_for_current_dictionary = sorted_spike_windows(:,4);
        detection_level_for_current_channel = sum(ismembertol(double(current_ground_truth_idxs),double(spike_idxs_for_current_dictionary),6,'DataScale',1))/length(current_ground_truth_idxs) * 100;
        stage_3_detection_levels(i) = detection_level_for_current_channel;
    catch
    end

end
disp([gt_to_use,max_detection_channel,detection_level,stage_2_detection_levels,stage_3_detection_levels]);
%%
channels_without_formatting = str2double(strrep(strrep(ordered_list_of_channels,"c",""),".mat",""));
run_clustering_algorithm_on_desired_tetrodes_ver_4(channel_wise_means,channel_wise_std,min_threshold,dir_with_channel_recordings,dictionaries_dir,config);





