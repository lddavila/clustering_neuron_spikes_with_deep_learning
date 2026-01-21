function [] = test_spike_windows_perf_with_new_method()

[dir_to_start,~,~] = fileparts(mfilename('fullpath'));
cd(dir_to_start);
home_dir = cd("..");
cd("..");
addpath(genpath(pwd))
cd(home_dir)
disp("Finished adding path");

config = spikesort_config();
disp("Finished getting config");



dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(config.parent_save_dir,"compare_ic_to_z_score"));

base_path = config.base_file_path;
%get all .mat files in default results directory
table_of_all_blind_pass_tables = struct2table(dir(string(fullfile(base_path,"Default_Results_Dir", '**', '*.mat'))));

%filter down to only the blind_pass_tables
table_of_all_blind_pass_tables = table_of_all_blind_pass_tables(string(table_of_all_blind_pass_tables{:,"name"})=="blind_pass_table.mat",:);

%filter down to only ones that are in a recording directory
table_of_all_blind_pass_tables = table_of_all_blind_pass_tables(contains(string(table_of_all_blind_pass_tables{:,"folder"}),"600Neuron300SecondRecordingWithLevel"),:);

sliced_table = slice_table_for_parallel_processing(table_of_all_blind_pass_tables,[]);

num_dps = config.NUM_DPTS_TO_SLICE;

%cycle through every recording

for i=1:height(table_of_all_blind_pass_tables)
    current_table = sliced_table{i};
    disp(current_table);
    current_bp_table = importdata(fullfile(string(current_table{1,"folder"}),string(current_table{1,"name"})));
    current_folder_name = current_table{1,"folder"};

    %get the number of channels & recording name
    if contains(current_folder_name,"_channels_")
        split_name = split(string(current_table{1,"folder"}),filesep,1);
        num_channels = str2double(split_name(end-1));
    else
        num_channels = 4;
    end
    current_recording = current_bp_table{1,"recording_name"};

    if contains(pwd,"10595")
        config.GT_FP = fullfile(config.base_file_path,"Data",current_recording,"ground_truth","ground_truth.mat");
        config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",current_recording,"timestamps","timestamps.mat");
        config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",current_recording,"recordings_by_channel");
    end
    if contains(pwd,"C:\Users\ldd77\")
        ext_drive_fp = "F:";
        config.GT_FP = fullfile(ext_drive_fp,current_recording,"ground_truth","ground_truth.mat");
        config.TIMESTAMP_FP = fullfile(ext_drive_fp,current_recording,"timestamps","timestamps.mat");
        config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(ext_drive_fp,current_recording,"recordings_by_channel");
    end


    %import the ground truth data for the recording
    ground_truth_array = importdata(config.GT_FP);

    %sometimes a bp table might not have the required cols due to unknown
    %errors
    %in this case we skip it
    if ~ismember(string(current_bp_table.Properties.VariableNames),"Max_Overlap_Unit")
        continue;
    end
    %get a unique list of all units that appear in the current recording
    unique_units = unique(current_bp_table{:,"Max_Overlap_Unit"});

    maxed_acc_example_for_unit= cell(length(unique_units),1);
    %for every unit that appears in the recording find where it's accuracy
    %is maxed out
    for j=1:length(unique_units)
        current_unit = unique_units(j);
        only_current_unit = current_bp_table(current_bp_table{:,"Max_Overlap_Unit"}==current_unit,:);
        [~,max_appearence] = max(only_current_unit{:,"accuracy"});
        maxed_acc_example_for_unit{j} = only_current_unit(max_appearence,:);
    end

    %for every highest accuracy get the % of unit spikes that appear in the
    %raw data as a fraction
    % unit_overlap_with_spike_windows =
    % number_of_gt_spikes_found_by_spike_windows / length(gt_spikes_for_unit)
    %get the same number using the ironclust data
    %by default it is 0 because that means our blind pass didn't find the
    %cluster at all and we have no comparison
    default_overlap = zeros(length(ground_truth_array),1);
    default_overlap_with_bandpass = zeros(length(ground_truth_array),1);
    ironclust_overlap_without_bandpass = zeros(length(ground_truth_array),1);
    ironclust_overlap_with_bandpass = zeros(length(ground_truth_array),1);
    % disp()
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = length(length(maxed_acc_example_for_unit));
    print_status_bar(num_iterations,current_recording +" with " +string(num_channels)+" channels")
    for j=1:length(maxed_acc_example_for_unit)
        current_maxed_example = maxed_acc_example_for_unit{j};
        gt_unit_to_use = current_maxed_example{1,"Max_Overlap_Unit"};
        current_channels = current_maxed_example{1,"grades"}{1}{49};
        gt_data = ground_truth_array{gt_unit_to_use}+1;
        desired_z_score = current_maxed_example{1,"Z Score"};
        ordered_list_of_channels = strcat("c",string(sort(current_channels)),".mat");
        %overwrite config to use default spike windows
        config.use_new_spike_detection = false;
        config.use_bandpass = false;
        [~,default_overlap(gt_unit_to_use)] = get_spike_windows_for_specific_channels(ordered_list_of_channels,config.DIR_WITH_OG_CHANNEL_RECORDINGS,desired_z_score,num_dps,gt_data,config);

        %overwrite the config so that
        %get_spike_windows_for_specific_channels will use the ironclust
        %spike detection but not the bandpass filter
        config.use_new_spike_detection = false;
        config.use_bandpass = true;
        [~,default_overlap_with_bandpass(gt_unit_to_use)] = get_spike_windows_for_specific_channels(ordered_list_of_channels,config.DIR_WITH_OG_CHANNEL_RECORDINGS,desired_z_score,num_dps,gt_data,config);


        %overwrite the config so that
        %get_spike_windows_for_specific_channels will use the ironclust
        %spike detection and the bandpass filter
        config.use_new_spike_detection = true;
        config.use_bandpass = false;
        [~,ironclust_overlap_without_bandpass(gt_unit_to_use)] = get_spike_windows_for_specific_channels(ordered_list_of_channels,config.DIR_WITH_OG_CHANNEL_RECORDINGS,desired_z_score,num_dps,gt_data,config);


        %overwrite the config so that
        %get_spike_windows_for_specific_channels will use the ironclust
        %spike detection and the bandpass filter
        config.use_new_spike_detection = true;
        config.use_bandpass = true;
        [~,ironclust_overlap_with_bandpass(gt_unit_to_use)] = get_spike_windows_for_specific_channels(ordered_list_of_channels,config.DIR_WITH_OG_CHANNEL_RECORDINGS,desired_z_score,num_dps,gt_data,config);
        % disp(j);
    end

    % default_overlap = zeros(length(ground_truth_array),1);
    % default_overlap_with_bandpass = zeros(length(ground_truth_array),1);
    % ironclust_overlap_without_bandpass = zeros(length(ground_truth_array),1);
    % ironclust_overlap_with_bandpass = zeros(length(ground_truth_array),1);
    data_to_save_struct = struct("default_overlap",default_overlap,"default_overlap_with_bandpass",default_overlap_with_bandpass,"ironclust_overlap_without_bandpass",ironclust_overlap_without_bandpass,"ironclust_overlap_with_bandpass",ironclust_overlap_with_bandpass);
    par_save(fullfile(fullfile(dir_to_save_results_to,current_recording + " " + string(num_channels) + " Channels.mat")),data_to_save_struct);
    %now create a line plot for each of them
    figure;
    plot(default_overlap)
    hold on;
    plot(default_overlap_with_bandpass)
    plot(ironclust_overlap_without_bandpass);
    plot(ironclust_overlap_with_bandpass);
    legend("Default","Default + banpass","ironclust - bandpass","ironclust + bandpass");
    title(current_recording + " " + string(num_channels) + " Channels");
    saveas(gcf,fullfile(dir_to_save_results_to,current_recording + " " + string(num_channels) + " Channels.svg"))
    close(gcf);
end
end