function [] = test_add_percentile_col()
home_dir = cd("..");
cd("..")
addpath(genpath(pwd));
cd(home_dir);
config = spikesort_config();
cluster_groups =importdata(fullfile(config.base_file_path,"Data","results_of_parallel_grouping.mat"));

if ~exist(fullfile(config.parent_save_dir,"testing_feature","cluster_groups_with_percentile.mat"),"file")
    cluster_groups_with_percentile = add_percentile_col(cluster_groups,config);
    dir_to_save = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"testing_feature"));
    cd(dir_to_save)
    save("cluster_groups_with_percentile.mat","cluster_groups_with_percentile");
else
    cluster_groups_with_percentile =importdata("cluster_groups_with_percentile.mat"); 
end

 recombined_groups = check_if_any_cluster_groups_can_be_combined(cluster_groups_with_percentile,config);


end