function [] = test_add_percentile_col()
home_dir = cd("..");
cd("..")
addpath(genpath(pwd));
cd(home_dir);
config = spikesort_config();
cluster_groups =importdata(fullfile(config,"Data","results_of_parallel_grouping.mat"));
cluster_groups_with_percentile = add_percentile_col(cluster_groups,config);

dir_to_save = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"testing_feature"));
cd(dir_to_save)
save("cluster_groups_with_percentile.mat","cluster_groups_with_percentile");

end