%add path
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir)
%% get a config file
config = spikesort_config();
%% Load data in
rec_6 = importdata(fullfile(config.base_file_path,"Default_Results_Dir","6_600Neuron300SecondRecordingWithLevel6Noise","blind_pass_table.mat"));
rec_7 = importdata(fullfile(config.base_file_path,"Default_Results_Dir","7_600Neuron300SecondRecordingWithLevel7Noise","blind_pass_table.mat"));
rec_8 = importdata(fullfile(config.base_file_path,"Default_Results_Dir","8_600Neuron300SecondRecordingWithLevel8Noise","blind_pass_table.mat"));
rec_9 = importdata(fullfile(config.base_file_path,"Default_Results_Dir","9_600Neuron300SecondRecordingWithLevel9Noise","blind_pass_table.mat"));
rec_10 = importdata(fullfile(config.base_file_path,"Default_Results_Dir","10_600Neuron300SecondRecordingWithLevel10Noise","blind_pass_table.mat"));
%% concatenate all the exmaples into single
all_mixed_results = [rec_6;rec_7;rec_8;rec_9;rec_10];
%% filter only down to those above 10% accuracy
