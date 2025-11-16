function run_tagging_features_for_grouped_clusters()
home_dir = cd("..");
cd("..")
addpath(genpath(pwd));
cd(home_dir);

config = spikesort_config();

list_of_all_cluster_groups = struct2table(dir(fullfile(config.base_file_path,"Default_Results_Dir","simple_grouping_per_recording","*.mat")));

dir_to_save_file_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"tags_matrix_per_recording"));

cd(dir_to_save_file_to);
for i=1:size(list_of_all_cluster_groups,1)
    current_group = importdata(fullfile(list_of_all_cluster_groups{i,"folder"}{1},list_of_all_cluster_groups{i,"name"}{1}));
    [~,tags_matrix] = add_group_tags_col(current_group,config);
    par_save(list_of_all_cluster_groups{i,"name"},tags_matrix)
end

end
