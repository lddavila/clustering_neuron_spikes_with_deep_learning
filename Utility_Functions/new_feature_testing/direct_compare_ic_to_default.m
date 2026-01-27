function [] = direct_compare_ic_to_default()
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
default_dir_parts = ["_600Neuron300SecondRecordingWithLevel","Noise"];
config = spikesort_config();
current_number_of_channels = 1;

for rec_num=1:10
    rng(0)
    ext_drive_fp = "F:";
    config.RECORDING_NAME = string(rec_num)+default_dir_parts(1)+string(rec_num)+default_dir_parts(2);
    config.GT_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"ground_truth","ground_truth.mat");
    config.TIMESTAMP_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"timestamps","timestamps.mat");
    config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(ext_drive_fp,config.RECORDING_NAME,"recordings_by_channel");
    table_of_channels = struct2table(dir(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS,"*.mat")));

    unit_locs = importdata(fullfile(ext_drive_fp,config.RECORDING_NAME,"ground_truth","neuron_unit_locations.mat"));
    unit_list = 1:length(unit_locs);
    channel_locs = importdata(fullfile(ext_drive_fp,config.RECORDING_NAME,"ground_truth","channel_locations.mat"));

    %randomly select 10 units and the channels that should be able to
    %detect them best
    % random_channels_to_test = 1:length(unit_locs)(randperm(height(table_of_channels),5),:);
    random_units_to_test = randperm(length(unit_list),10);

    %create an array that will store the detected spikes
    cell_array_of_spikes_per_channels_default = cell(length(random_units_to_test),1);
    cell_array_of_spikes_per_channels_ic = cell(length(random_units_to_test),1);

    for default_or_not=0:1
        if default_or_not
            config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(ext_drive_fp,config.RECORDING_NAME+"_"+string(current_number_of_channels)+"_channels_default");
            config.use_bandpass = false;
            config.use_new_spike_detection = false;
        else
            config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(ext_drive_fp,config.RECORDING_NAME+"_"+string(current_number_of_channels)+"_channels_ironclust");
            config.use_bandpass = false;
            config.use_new_spike_detection = false;
        end


        %calculate which channels are the closest to each of those units
        %and use those channels to cluster

        closest_channel = nan(length(random_units_to_test),1);
        for i=1:length(random_units_to_test)
            distances_between_unit_and_channels = vecnorm((unit_locs(random_units_to_test(i),1:2) - channel_locs).');
            [~,closest_channel(i)] = min(distances_between_unit_and_channels);
        end

        %run spike detection for all those channels
        
    end
end
end