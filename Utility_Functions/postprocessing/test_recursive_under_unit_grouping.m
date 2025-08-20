function [] = test_recursive_under_unit_grouping()
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
config = spikesort_config();
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
disp("Finished Loading Blind Pass Table ")

home_dir = cd("..");
cd("..")
addpath(genpath(pwd));
disp("Finished adding path")
config = spikesort_config();
cd(home_dir);

c = parcluster('local');
c.JobStorageLocation = config.BLIND_PASS_DIR_PRECOMPUTED;
saveAsProfile(c, 'local_scratch');
parpool('local_scratch', 40); 

config.RECORDING_NAME = "10_100";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,config.RECORDING_NAME);
c1 = blind_pass_table{:,"is_neuron"}==1;
c2 = blind_pass_table{:,"grades_pred"} >0;
blind_pass_table_only_neur_filtered = blind_pass_table(boolean(c1)& boolean(c2),:);
disp("Finsihed filtering")

final_cluster_groups = recursive_under_unit_grouping(blind_pass_table_only_neur_filtered,config);

fp_to_save_to = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"recursive_under_unit_grouping_results");
save(final_cluster_groups, fp_to_save_to);
disp("Finished saving recursive under unit grouping results");
end