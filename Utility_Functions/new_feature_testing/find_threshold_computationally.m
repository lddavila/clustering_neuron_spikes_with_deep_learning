function [] = find_threshold_computationally(recording_name,varargin)
%definitions:
%MUA is short for multi-unit-activty
%this function's goal will be to try and quantify what filtering thresholds
%will be ideal for different neurons that surround the channel
%an example follows
%Suppose a Channel 1
% Neuron A is distance X from Channel 1
%Neuron B is distance 1.5 * X from Channel 1
%neuron C is distance 2.0 * x from channel 1
%Let a theoretical threshold theta exist
%With the threshold theta we detect the following:
% 99% of Neuron A's activity + a hundred MUA spikes
% 50% of Neuron B's activity + one MUA spike
%10% of Neuron C's activity + 0 MUA spikes
%if we select a less strict threshold, called beta we might detect
% 100% of Neuron A's activity + a thousand MUA spikes
% 90% of Neuron B's activity + a hundred MUA spikes
%50% of Neuron C's activity + 10 MUA spikes

%there is some theoretical ideal that will detect maximize signal activity
%and minimize MUA spikes
%we'll try to find this threshold by finding how many neurons can be
%detected with certain accuracy by a certain channel

%the interesting thing about this problem is that you're trying to find a
%threshold that will optimize coverage and signal without including a lot
%of MUA

home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir)

%get a config file
config = spikesort_config();

config.RECORDING_NAME = recording_name;

%if extra variables were passed in then the first should be the base file
%path which should be used instead of the default created by the config
if ~isempty(varargin)
    config.base_file_path = varargin{1};
else
    config.RECORDING_NAME = "Data/"+recording_name;
end

%get the ground truth data
config.GT_FP = fullfile(config.base_file_path,config.RECORDING_NAME,"ground_truth","ground_truth.mat");
disp(config.GT_FP)
unit_gr_tr = importdata(config.GT_FP);

%get the channel locations
channel_locs = importdata(fullfile(config.base_file_path,config.RECORDING_NAME,"ground_truth","channel_locations.mat"));

%get the unit locations
unit_locs = importdata(fullfile(config.base_file_path,config.RECORDING_NAME,"ground_truth","neuron_unit_locations.mat"));

%get the timestamp data
config.TIMESTAMP_FP = fullfile(config.base_file_path,config.RECORDING_NAME,"timestamps","timestamps.mat");
% timestamps = importdata(config.TIMESTAMP_FP);

%set the channel filepath
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,config.RECORDING_NAME,"recordings_by_channel");

%get table of channels
table_of_channels = struct2table(dir(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS,"*.mat")));


%add numerical representation to table of channels so we can sort them
table_of_channels.channel_number = str2double(strrep(strrep(string(table_of_channels{:,"name"}),"c",""),".mat",""));

%sort the table
table_of_channels = sortrows(table_of_channels,"channel_number","ascend");

%set some thresholds that will be used for the default method and ironclust
default_thresholds = 10:0.1:50;
ironclust_thresholds = 10:0.1:50;



%now for every channel we'll want to see how many ground truth units can be
%detected while adding the least amount of noise possible

%create a file where the distances will be saved to
save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,config.RECORDING_NAME,"channel_distances_to_units"));

%this will be accomplished by sorting the ground truth units by their
%distance to the current channel
for i=1:height(table_of_channels)
    %get the distance between the current channel and all the ground truth
    %units
    save_file_name = fullfile(save_dir,"c"+string(i)+".mat");

    dists = vecnorm(channel_locs(i,:) - unit_locs(:,1:2), 2, 2);
    disp("Finished computing distances")

    %create a local table to make sorting easier
    table_of_distance = table((1:length(unit_gr_tr)).',dists,'VariableNames',["Unit","Distance"]);

    %import the current channel data
    current_channel_data = importdata(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS,"c"+string(i)+".mat"));
    disp("Finished importing channel data");


    %sort rows by distance
    table_of_distance = sortrows(table_of_distance,"Distance","ascend");
    disp("Finished sorting by distance")
    %now using the detected spikes let's see how many of the found spikes
    %correlate to some ground truth unit vs how many don't correlate to any
    %units
    %because we need some threshold we'll set it to within 100 microns
    %this is a magic number and we can change it if we want to make it
    %higher
    % table_of_distance = table_of_distance(table_of_distance<100,:);

    %now run both spike detection methods for the current channel
    disp("Running new spike detection for c"+string(i));
    fp_to_save_ironclust_images = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(save_dir,"c"+string(i)+"_ironclust_thresholds"));
    [ironclust_spike_det_results,ironclust_noise_ratio,ironclust_raw_unit_numbers,ironclust_raw_noise_numbers,ic_thresholds]= get_detected_spikes(current_channel_data,default_thresholds,ironclust_thresholds,unit_gr_tr(table_of_distance.Unit),config,fp_to_save_ironclust_images);
    config.use_new_spike_detection = false;
    disp("Running default spike detection for c"+string(i));
    fp_to_save_default_images = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(save_dir,"c"+string(i)+"_default_thresholds"));
    [default_spikes_det_results,default_noise_ratio,default_raw_unit_numbers,default_raw_noise_number,d_thresholds]= get_detected_spikes(current_channel_data,default_thresholds,ironclust_thresholds,unit_gr_tr(table_of_distance.Unit),config,fp_to_save_default_images);

    %create a struct to save this data to avoid repitition
    data_struct = struct;
    data_struct.("ironclust_ratios") = ironclust_spike_det_results;
    data_struct.("ironclust_noise_ratio") = ironclust_noise_ratio;
    data_struct.("ironclust_raw_unit_numbers")= ironclust_raw_unit_numbers;
    data_struct.("ironclust_raw_noise_numbers") = ironclust_raw_noise_numbers;
    data_struct.("ironclust_thresholds") = ic_thresholds;

    data_struct.("default_spikes_det_results") = default_spikes_det_results;
    data_struct.("default_noise_ratio") = default_noise_ratio;
    data_struct.("default_raw_unit_numbers") =default_raw_unit_numbers;
    data_struct.("default_raw_noise_number") =default_raw_noise_number;
    data_struct.("table_of_distance") =table_of_distance;
    data_struct.("default_thresholds") = d_thresholds;

    par_save(save_file_name,data_struct)
    disp("Finished saving for c"+string(i));






end

end