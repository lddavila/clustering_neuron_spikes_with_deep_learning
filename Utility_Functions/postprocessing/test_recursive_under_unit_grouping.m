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
fp_to_save_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"recursive_under_unit_grouping_results"));
home_dir = cd(fp_to_save_to);


final_cluster_groups = recursive_under_unit_grouping(blind_pass_table,config);


save("final_results.mat","final_cluster_groups");
disp("Finished saving recursive under unit grouping results");
end