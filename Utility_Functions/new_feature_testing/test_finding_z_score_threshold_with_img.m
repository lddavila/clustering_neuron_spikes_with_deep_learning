function [] = test_finding_z_score_threshold_with_img()
%in this file we will attempt to find the ideal clustering threshold for a
%tetrode by using an nth dimensional view of the cluster
%we will assume that the range exists somewhere between a z score of 3 and
%a z score of 12
%and we will try to train a q-learning agent to find the ideal threshold by
%giving it a plot of the clusters and allowing it to increase/decrease the
%z score via binary search
%we'll also do several steps that are normally done in
%run_entire_clustering_algorithm here to avoid revisiting them again during
%clustering
%this is again in an effort to optimize for speed
clc;

warning('off') %we are disabling warnings because those produced are expected and no cause for concern

%set the lower/upper bounds that will be used for cutting
lower = 3;
upper = 12;


% add the path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);


%set the seed for reproducability
rng(0,'twister');

% get a default config file
config = spikesort_config();

%override the default config file to use a different save directory
config.RECORDING_NAME = "img_threshold_finding";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"img_threshold_finding");
startup;
disp("Finished Setting Recording Name")

%override the default config file to point towards the recording we'll be
%using for these tests
config.GT_FP = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","ground_truth","ground_truth.mat");
config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","recordings_by_channel");
disp("Finished Setting directories")

%get the scale factor
scale_factor = config.SCALE_FACTOR;

%get a list of what is already done
list_of_existing_files =struct2table(dir(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"**",".")));
rows_to_exclude = string(list_of_existing_files{:,"name"}) == "." | string(list_of_existing_files{:,"name"})=="..";
list_of_existing_files(rows_to_exclude,:) = [];
what_is_computed = fullfile(string(list_of_existing_files{:,"folder"}),string(list_of_existing_files{:,"name"}));
config.ALREADY_DONE_FILES = what_is_computed;


%override the config file so that it uses differnt z scores
%7.5 is the z score used by default as it is the midpoint between 3 and 12
config.DEFAULT_CLUSTERING_Z_SCORES = 7.5;

%create the z score directory 
if ~ismember(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"z_score"),what_is_computed) %means that the z_score matrix is already computed and we will skip computing it again
   z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"z_score")); %not yet computed
else
   z_score_dir = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"z_score");
end
disp("Finished Creating Z Score Directory");
%disp(z_score_dir);

%create the directory for the template files
create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"Shape_Template_PNGs"));



%load the timestamps into memory
timestamps = importdata(config.TIMESTAMP_FP);
disp("Finished Importing timestamps for recording")

%get the ordered list of channels
ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);

%get the channel statistics 
beginning_time = tic;
[channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,config.DIR_WITH_OG_CHANNEL_RECORDINGS,z_score_dir,scale_factor,config,what_is_computed); %will get the mean and std of every channel and calculate z_score for data set if not yet created
mean_and_std_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std"));
save(fullfile(mean_and_std_dir,"mean_and_std.mat"),"channel_wise_means","channel_wise_std");
end_time = toc(beginning_time);
fprintf("Finished Getting mean and std, it took %f seconds\n",end_time)





%run the clustering algorithm with just the default z score first in order
%to avoid repetitive work when resetting function we start with the
%baseline ratio when we perfrom a spike cutting at 7.5
% ratio0 = modified_run_entire_clustering_algorithm_for_img_analysis(config);
%doing this here avoids work later
% disp("Finished initial blind pass")

%find all spikes where the z score is at least the lower bound 
spikes_per_channel_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"spikes_per_channel min_z_score "+string(lower)));
detect_spikes_ver_2(spikes_per_channel_dir,ordered_list_of_channels,config.DIR_WITH_OG_CHANNEL_RECORDINGS,z_score_dir,lower,scale_factor,config);

%now get the modified spike windows where the z score is at least the lower bound
spike_windows_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"spike_windows min_z_score " + string(lower) + " num dps "+ string(config.NUM_DPTS_TO_SLICE)));
get_lowest_bound_spike_windows(ordered_list_of_channels,spikes_per_channel_dir,lower,config.NUM_DPTS_TO_SLICE,z_score_dir,spike_windows_dir,config)



%let us get the agent and critique net that will be used
number_of_features =60003 ; % to reflect the image, ratio, and z score given 
num_neurons = 15; %a simple test value
num_layers = 15; %a simple test value
current_eps = 0.1; %this epsilon value encourages more random movement
[agent,~,obs_info,action_info] = get_agent_and_critique_net_for_finding_z_score_with_img(number_of_features,num_neurons,num_layers,current_eps);
disp("Finished getting agent and critique net");


%cut down the tetrodes you can test on to only the tetrodes whose channels
%are all present in the file
tetrode_array = config.ART_TETR_ARRAY;
list_of_available_channels = struct2table(dir(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS,"*.mat")));
list_of_available_channels = string(list_of_available_channels{:,"name"});
list_of_available_channels = strrep(list_of_available_channels,".mat","");
list_of_available_channels = strrep(list_of_available_channels,"c","");
list_of_available_channels = str2double(list_of_available_channels);

all_channels_are_available = ismember(tetrode_array,list_of_available_channels);
tetrode_array(~all(all_channels_are_available,2),:) = [];


%now get the reset handle
ResetHandle = @() custom_reset_function_for_finding_z_score_using_img(config,lower,upper,spike_windows_dir,tetrode_array);
disp("Finished getting the custom reset function")

%now get the step function
StepHandle = @(Action,Info) custom_step_function_for_finding_z_score_threshold_using_img(Action,Info,config,lower,upper,spike_windows_dir,timestamps,channel_wise_means,channel_wise_std);
disp("Finished getting the step function")
%now set the training options
opt = rlTrainingOptions(MaxEpisodes=500, ...
    MaxStepsPerEpisode=500, ...,
    Verbose=1,...
    plots = "none",...
    SaveAgentCriteria="AverageReward", ...
    StopTrainingCriteria="None",...
    StopOnError="off");
disp("Finished setting options")

%now get the enviornment that the agent will train in
env = rlFunctionEnv(obs_info,action_info,StepHandle,ResetHandle);
disp("Finished validating the enviornment")

%now train the agent
train(agent,env,opt);
disp("Finished Training")

end