%% STEP 1: Add functions to your path
examples_dir = cd("..");
addpath(genpath(pwd));
cd(examples_dir);

%% step 2: Get the config Necessary for current Example
config = spikesort_config();
startup;
%% Step 3 Download Necessary Data
run_me_to_download_data("9c2e6016-544e-48b9-906c-474836e003fe","10.70122/FK2/BVPIJO",config,false);
%% run the blind pass with a various min_z_score (cut threshold) 
blind_pass_table = run_entire_clustering_algorithm_ver_2(config);
%% select the neurons from the blind pass
%% Merge neurons into groups that represent the same underlying unit
determine_which_blind_pass_neurons_overlap(blind_pass_table,config)
%% 