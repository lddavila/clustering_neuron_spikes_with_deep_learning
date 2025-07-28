function [] = test_check_cluster_groups_for_consistent_overlap()
fp_to_cluster_groups = "/scratch/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/10_100/blind_pass_table_organized_into_same_groups_with_filter/clusters_organized_by_same_group.mat";
cluster_groups = importdata(fp_to_cluster_groups);
disp("Finished Loading Cluster Groups")

home_dir = cd("..");
cd("..")
addpath(genpath(pwd));
disp("Finished adding path")
config = spikesort_config();
cd(home_dir);

expanded_cluster_groups = check_cluster_groups_for_consistent_overlap(cluster_groups,config);
config.RECORDING_NAME = "10_100";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,config.RECORDING_NAME);

c = parcluster('local');
c.JobStorageLocation = config.BLIND_PASS_DIR_PRECOMPUTED;
saveAsProfile(c, 'local_scratch');
parpool('local_scratch', 37); 


abs_path = create_a_file_if_doesnt_exist_and_return_abs_path("/scratch/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/10_100/blind_pass_table_organized_into_same_groups_with_filter/expanded");
disp("Finished creating save dir")
save(fullfile(abs_path,"expanded_cluster_groups.mat"), 'expanded_cluster_groups');
end