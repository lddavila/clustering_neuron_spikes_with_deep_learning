%% STEP 1: Add functions to your path
examples_dir = cd("..");
addpath(genpath(pwd));
cd(examples_dir);

%% step 2: Get the config Necessary for current Example
config = spikesort_config();
config.RECORDING_NAME = "0_100";
startup;
%% (OPTIONAL STEP 2 CONTINUED) SET THE filepath of the ground truth files if your recording is simulated and they are available
config.GT_FP = fullfile(config.base_file_path,"Data","0_100","ground_truth","0_100Neuron300SecondRecordingWithLevel3Noise.h5.mat");
config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data","0_100","timestamps","timestamps.mat");
%% Step 3: Download Necessary Data
run_me_to_download_data("9c2e6016-544e-48b9-906c-474836e003fe","10.70122/FK2/BVPIJO",config,false);
%% Step 4: run the blind pass with a various min_z_score (cut threshold) 
[blind_pass_table,fp_to_bp_table] = run_entire_clustering_algorithm_ver_2(config);
%% Step 5: select the neurons from the blind pass
blind_pass_table_only_neurons = blind_pass_table(blind_pass_table{:,"is_neuron"},:);
%% (OPTIONAL STEP 5 CONTINUED) Get max overlap unit and accuracy cols for the neurons 
%This is only possible if your recording is simulated and the ground truth
%is provided
%in this example the data is simulated and the ground truth is available
blind_pass_table_only_neurons = add_overlap_percentage_col_and_max_overlap_unit(blind_pass_table,config);
blind_pass_table_only_neurons = add_accuracy_col(config,blind_pass_table_only_neurons);
%% Step 6: Use Accuracy Prediction Neural Network to filter out any MUA clusters that made it past the first filter
blind_pass_table_only_neurons = add_accuracy_cat_pred_from_nn(blind_pass_table,config);
bp_table_only_neur_filtered = blind_pass_table_only_neurons(blind_pass_table{:,"predicted_accuracy_cat"}>0,:);
%% Step 7: Merge neurons into groups that represent the same underlying unit
clusters_organized_by_same_group = determine_which_blind_pass_neurons_overlap(bp_table_only_neur_filtered,config);
%% Step 9: Save Results of merging
clusters_organized_by_same_group_with_filter_fp = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table_organized_into_same_groups_with_filter");
create_a_file_if_it_doesnt_exist_and_ret_abs_path(clusters_organized_by_same_group_with_filter_fp);
save(fullfile(clusters_organized_by_same_group,"clusters_organized_by_same_group.mat"),"clusters_organized_by_same_group");
%% Step 10: Merge Neurons into groups without step 6 (for testing purposes)
clusters_organized_by_same_group_without_filter = determine_which_blind_pass_neurons_overlap(blind_pass_table_only_neurons, config);
%% step 11: Save the results of step 10 
clusters_organized_by_same_group_without_filter_fp = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table_organized_into_same_groups_without_filter");
create_a_file_if_it_doesnt_exist_and_ret_abs_path(clusters_organized_by_same_group_without_filter_fp);
save(fullfile(clusters_organized_by_same_group_without_filter_fp,"clusters_organized_by_same_group_without_filter.mat"),"");