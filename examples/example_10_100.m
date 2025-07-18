%% STEP 1: Add functions to your path
examples_dir = cd("..");
addpath(genpath(pwd));
cd(examples_dir);
disp("Finished Adding path")
%% step 2: Get the config Necessary for current Example
config = spikesort_config();
config.RECORDING_NAME = "10_100";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,config.RECORDING_NAME);
startup;
disp("Finished Setting Recording Name")
%% (OPTIONAL STEP 2 CONTINUED) SET THE filepath of the ground truth files if your recording is simulated and they are available
config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","10_100Neuron300SecondRecordingWithLevel1Noise.h5.mat");
config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
disp("Finished Setting directories")
% disp(config.GT_FP);
% disp(config.TIMESTAMP_FP);
% disp(config.DIR_WITH_OG_CHANNEL_RECORDINGS);
%% SKIPPABLE STEP: HERE I SET THE job location to a directory, need not be run generally
c = parcluster('local');
c.JobStorageLocation = '/scratch/lddavila/matlab_job_storage';
saveAsProfile(c, 'local_scratch');
parpool('local_scratch', 37); 
%% Step 3: Download Necessary Data
%run_me_to_download_data("10.7910/DVN/JWATDZ",config,true,config.RECORDING_NAME);
disp("Finished Downloading Data");
%% Step 4: run the blind pass with a various min_z_score (cut threshold) 
very_beginning_time = tic;
[blind_pass_table,fp_to_bp_table] = run_entire_clustering_algorithm_ver_2(config);
end_time = toc(very_beginning_time);
fprintf("Finished running blind pass it took %f seconds",end_time)
%% Step 5: select the neurons from the blind pass
blind_pass_table_only_neurons = blind_pass_table(blind_pass_table{:,"is_neuron"},:);

%% (OPTIONAL STEP 5 CONTINUED) Get max overlap unit and accuracy cols for the neurons 
%This is only possible if your recording is simulated and the ground truth
%is provided
%in this example the data is simulated and the ground truth is available
beginning_time = tic;
blind_pass_table_only_neurons = add_overlap_percentage_col_and_max_overlap_unit(blind_pass_table_only_neurons,config);
blind_pass_table_only_neurons = add_accuracy_col(config,blind_pass_table_only_neurons);
end_time = toc(beginning_time);
fprintf("Finished adding overlap and accuracy columns it took %f seconds",end_time)
%% Step 6: Get accuracy category prediction using grades + universal rank neural network 
beginning_time = tic;
blind_pass_table_only_neurons = add_accuracy_cat_pred_from_nn(blind_pass_table_only_neurons,config);
end_time = toc(beginning_time);
fprintf("Finished adding accuracy cat predictions it took %f seconds",end_time)
%% step 7: Get Accuracy category prediction using mean waveform neural network
blind_pass_table_only_neurons = add_mean_waveform_pred_col(blind_pass_table_only_neurons,config);

%% step 8: Get Letter Grade
blind_pass_table_only_neurons = add_letter_grade_based_on_nn(blind_pass_table_only_neurons);
%% Step 8: Use Accuracy Prediction Neural Network to filter out any MUA clusters that made it past the first filter
bp_table_only_neur_filtered = blind_pass_table_only_neurons(blind_pass_table{:,"grades_pred"}>0,:);

%% Step 9: Merge neurons into groups that represent the same underlying unit
beginning_time = tic;
clusters_organized_by_same_group = determine_which_blind_pass_neurons_overlap(bp_table_only_neur_filtered,config);
end_time = toc(beginning_time);
fprintf("Finished merging clusters it took %f seconds",end_time)
%% Step 10: Save Results of merging
clusters_organized_by_same_group_with_filter_fp = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table_organized_into_same_groups_with_filter");
create_a_file_if_it_doesnt_exist_and_ret_abs_path(clusters_organized_by_same_group_with_filter_fp);
save(fullfile(clusters_organized_by_same_group,"clusters_organized_by_same_group.mat"),"clusters_organized_by_same_group");

%% Step 11: Merge Neurons into groups without step (for testing purposes)
clusters_organized_by_same_group_without_filter = determine_which_blind_pass_neurons_overlap(blind_pass_table_only_neurons, config);

%% step 12 : Save the results of step 11 
clusters_organized_by_same_group_without_filter_fp = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table_organized_into_same_groups_without_filter");
create_a_file_if_it_doesnt_exist_and_ret_abs_path(clusters_organized_by_same_group_without_filter_fp);
save(fullfile(clusters_organized_by_same_group_without_filter_fp,"clusters_organized_by_same_group_without_filter.mat"),"clusters_organized_by_same_group_without_filter");

%% step 13: Sort the Results of step 9
sorted_cluster_groups = use_choose_better_to_sort_groups(clusters_organized_by_same_group,config);
very_end_time = toc(very_beginning_time);
fprintf("Finished entire algorithm it took %f seconds",very_end_time)
%% Step 13a: Save the sorted groups cell array
fp_to_sorted_groups = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"Sorted Only Neurons Filtered");
create_a_file_if_it_doesnt_exist_and_ret_abs_path(fp_to_sorted_groups);
save(fullfile(fp_to_sorted_groups,"sorted_cluster_groups.mat"),"sorted_cluster_groups");
%% (OPTIONAL) STEP 13b: Check if the combinational neural network predicts an accuracy increases from merging the top results of the groups


%% step 14: Sort the results of step 11
sorted_cluster_groups_no_filter = use_choose_better_to_sort_groups(clusters_organized_by_same_group_without_filter,config);

%% step 14a: Save the results of step 14
clusters_organized_by_same_group_no_filter_fp = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"Sorted Only Neurons No Filter");
create_a_file_if_it_doesnt_exist_and_ret_abs_path(clusters_organized_by_same_group_no_filter_fp);
save(fullfile(clusters_organized_by_same_group_no_filter_fp,"sorted_cluster_groups_no_filter.mat"),"sorted_cluster_groups_no_filter");

%% (OPTIONAL) STEP 14b: Check if the combinational Neural Network Predicts an accuracy increases from merging the top results of the groups

