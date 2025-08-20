function [] = test_recursive_under_unit_grouping()
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
config = spikesort_config();
blind_pass_table = importdata(fullfile(config.base_file_path,"Data","final_table_with_overlap_only_neurons.mat"));
disp("Finished Loading Blind Pass Table ")

c = parcluster('local');
c.JobStorageLocation = config.BLIND_PASS_DIR_PRECOMPUTED;
saveAsProfile(c, 'local_scratch');
parpool('local_scratch', 40); 

config.RECORDING_NAME = "10_100";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,config.RECORDING_NAME);


final_cluster_groups = recursive_under_unit_grouping(blind_pass_table,config);

fp_to_save_to = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"recursive_under_unit_grouping_results");
save(final_cluster_groups, fp_to_save_to);
disp("Finished saving recursive under unit grouping results");
end