function [] = test_different_z_score_thresholds()
%in this file we will attempt to find a threshold between a z score of 3
%and 4 which will maximize the number good clusters we find
%to accomplish this we'll build an agent to navigate the space between 3
%and 4

% add the path
home_dir = cd("..");
cd("..");

addpath(genpath(pwd));
cd(home_dir);

%set the seed for reproducability
rng(0,'twister');

% get a default config file
config = spikesort_config();

%override the config file so that it uses differnt z scores
config.DEFAULT_CLUSTERING_Z_SCORES = 3:0.01:4;

%override the default config file to use a different save directory
config.RECORDING_NAME = "threshold_tests";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"threshold_tests");
startup;
disp("Finished Setting Recording Name")

%override the default config file to point towards the recording we'll be
%using for these tests
config.GT_FP = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","ground_truth","ground_truth.mat");
config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","recordings_by_channel");
disp("Finished Setting directories")

%let us get the agent and critique net that will be used
number_of_features = 2; %to reflect the only information the agent gets to have is the z score and the last accuracy accuracy ratio we found
num_neurons = 5; %a simple test value
num_layers = 5; %a simple test value
current_eps = 0.1; %this epsilon value encourages more random movement
[agent,~,obs_info,action_info] = get_agent_and_critique_net_for_verbose_states(number_of_features,num_neurons,num_layers,current_eps);

%now get the reset handle
ResetHandle = @() custom_reset_function_for_finding_z_score_threshold(config);

%now get the step function
StepHandle = @(Action,Info) custom_step_function_for_finding_z_score_threshold(Action,Info);

%now set the training options
opt = rlTrainingOptions(MaxEpisodes=500, ...
    MaxStepsPerEpisode=500, ...,
    Verbose=0,...
    plots = "none",...
    SaveAgentCriteria="AverageReward", ...
    StopTrainingCriteria="None",...
    StopOnError="off");

%now get the enviornment that the agent will train in
env = rlFunctionEnv(obs_info,action_info,StepHandle,ResetHandle);

%now train the agent
train(agent,env,opt);


end