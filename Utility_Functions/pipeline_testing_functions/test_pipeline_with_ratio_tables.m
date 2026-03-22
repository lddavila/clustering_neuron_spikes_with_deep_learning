%% Add path and functions
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir)
%% Get config file
config = spikesort_config;  
%% overwrite the base file path
config.base_file_path = "F:";
%% set the recording name
config.RECORDING_NAME = "10_600Neuron300SecondRecordingWithLevel10Noise";
%% set the data directory
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,config.RECORDING_NAME,"recordings_by_channel");
%% Import the ratio tables
unit_2_table_of_ratios = importdata("F:\tables_of_overlap\Unit_2.mat");
unit_4_table_of_ratios = importdata("F:\tables_of_overlap\Unit_4.mat");
%% create plots for the ratio tables
analyze_threshold_table(unit_2_table_of_ratios,4);
analyze_threshold_table(unit_4_table_of_ratios,4);
%% create sample tetrodes to run through the pipeline
unit_3_tetrode = [208, 32, 299,162];
unit_2_tetrode = [322,323,208,227];
ordered_list_of_channels = strcat("c",string(sort([unit_2_tetrode,unit_3_tetrode,53],"ascend")),".mat");
%% import the unfiltered data into a dictionary
unfiltered_data = containers.Map('KeyType','char','ValueType','any');
for i=1:length(ordered_list_of_channels)
    unfiltered_data(ordered_list_of_channels(i)) = importdata(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS,ordered_list_of_channels(i)));
end

%% set which channel you want to test
which_channel_to_test = 2;
number_of_dpts_on_either_side = 30;
number_of_gt_idxs_to_plot = 5;
unit_idxs = ground_truth{4};
% filter the data and store it in a new dictionary for quick comparsion
filtered_data = containers.Map('KeyType','char','ValueType','any');
for i=1:length(ordered_list_of_channels)
    filtered_data(ordered_list_of_channels(i))= filt_car_(unfiltered_data(ordered_list_of_channels(i)),config);
    
end

% plot the unfiltered vs the filtered

for i=which_channel_to_test:which_channel_to_test+.5%length(ordered_list_of_channels)
    f = figure;
    tiledlayout(2,number_of_gt_idxs_to_plot);
    y_data_unfiltered = unfiltered_data(ordered_list_of_channels(i));
    for j=1:number_of_gt_idxs_to_plot
        nexttile();
        window_start = unit_idxs(j)-number_of_dpts_on_either_side;
        window_end = unit_idxs(j)+number_of_dpts_on_either_side;
        subset_x_data = window_start:window_end;
        subset_y_data_unfiltered = y_data_unfiltered(window_start:window_end) * -1;
        plot(subset_x_data,subset_y_data_unfiltered);
        hold on;
        scatter(unit_idxs(j),y_data_unfiltered(unit_idxs(j))*-1);
        if j==1
            ylabel("Unfiltered");
        end
    end
    
    y_data_filtered = unfiltered_data(ordered_list_of_channels(i));
    for j=1:number_of_gt_idxs_to_plot
        nexttile();
        window_start = unit_idxs(j)-number_of_dpts_on_either_side;
        window_end = unit_idxs(j)+number_of_dpts_on_either_side;
        subset_x_data = window_start:window_end;
        subset_y_data_filtered = y_data_filtered(window_start:window_end)*-1;
        plot(subset_x_data,subset_y_data_filtered);
        hold on;
        scatter(unit_idxs(j),y_data_filtered(unit_idxs(j))*-1);
        if j==1
            ylabel("Unfiltered");
        end
    end
    sgtitle(ordered_list_of_channels(i));
end

%% set the tetrodes to use
config.ART_TETR_ARRAY = [unit_3_tetrode;unit_2_tetrode];
%% create a test directory to save everything to
test_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"deep testing"));
config.BLIND_PASS_DIR_PRECOMPUTED = test_dir;
%% get mean and std of all channels
z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"z score"));
[channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,config.DIR_WITH_OG_CHANNEL_RECORDINGS,z_score_dir,config.SCALE_FACTOR,config,[""]);

%% load in the new blind pass table 
new_10_bp_table = importdata("F:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\blind_pass_table.mat");

%% filter down to only those whose accuracy is greater than 80
only_80s = new_10_bp_table(new_10_bp_table{:,"accuracy"}>=80,["Z Score","Max_Overlap_Unit","accuracy",]);
unique_max_overlap_units = unique(only_80s.Max_Overlap_Unit);
%% get the average amplitude for each of them 
cell_array_of_highest = cell(length(unique_max_overlap_units),1);
for i=1:length(unique_max_overlap_units)
    current_gt_ts = ground_truth{unique_max_overlap_units(i)};
    only_curr_gt = only_80s(only_80s{:,"Max_Overlap_Unit"}==unique_max_overlap_units(i),:);
    [the_max_acc,max_index] = max(only_curr_gt{:,"accuracy"});
    the_multiplier_to_use = only_curr_gt{max_index,"Z Score"}:.1:only_curr_gt{max_index,"Z Score"}+1;
    cell_array_of_highest{i} = get_average_amplitude_per_unit_on_each_channel("F:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\filtered_data",current_gt_ts,6,[],the_multiplier_to_use);
end

%% get the ground truth cell 28 
ground_truth_cell_28 = importdata("F:\cell_28\ground_truth\ground_truth.mat");
table_of_ratios_cell_28 = get_average_amplitude_per_unit_on_each_channel("F:\cell_28\recordings_by_channel",ground_truth_cell_28,6);