% Quick end-to-end check of run_entire_clustering_algorithm_ver_2 on 4
% channels of the 10_100 recording. Results go to a fresh temp folder so
% nothing in Default_Results_Dir is reused or overwritten.
%
% Run from a terminal:
%   matlab -batch "run('<path to this file>')"

project_dir = fileparts(fileparts(mfilename("fullpath")));
cd(project_dir); % spikesort_config needs to be run from inside the project
addpath(genpath(project_dir));

config = spikesort_config();
data_dir = fullfile(config.base_file_path,"Data","10_100");
config.RECORDING_NAME = "10_100";
config.TIMESTAMP_FP = fullfile(data_dir,"timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(data_dir,"recordings_by_channel");
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(tempdir,"smoke_test_10_100_" + string(datetime("now","Format","yyyyMMdd_HHmmss")));
% apply_filter currently fails on row-vector recordings, so skip filtering
config.use_bandpass = false;

channels = ["c1.mat","c2.mat","c97.mat","c98.mat"];
% later stages build tetrodes from every recording in the folder, so limit
% the tetrode groupings to the channels being tested
config.ART_TETR_ARRAY = [1 2 97 98];
config.max_channel_number = max(config.ART_TETR_ARRAY,[],"all");
disp("Results folder: " + config.BLIND_PASS_DIR_PRECOMPUTED);
start_time = tic;
[blind_pass_table,fp_to_blind_pass_table,config] = run_entire_clustering_algorithm_ver_2(config,"ordered_list_of_channels",channels);
fprintf("SMOKE TEST PASSED: %d clusters in %.0f seconds\n",height(blind_pass_table),toc(start_time));
