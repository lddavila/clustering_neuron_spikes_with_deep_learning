function [] = test_parallel_vs_non_parallel()

home_dir = cd("..");
cd("..");

addpath(genpath(pwd));
cd(home_dir);

config = spikesort_config();
disp(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
disp("Finished importing blind pass table ")

dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"parallel_vs_not"));

cd(dir_to_save_results_to)
all_files_in_dir = struct2table(dir(fullfile(pwd,"*.mat")));
all_files_in_dir = string(all_files_in_dir{:,"name"});
%run non-parallel merge
if contains(all_files_in_dir,"results_of_non_parallel_grouping.mat")
    results_of_non_parallel_grouping = importdata(fullfile(dir_to_save_results_to,"results_of_non_parallel_grouping.mat"));
else
    results_of_non_parallel_grouping = determine_which_blind_pass_neurons_overlap(blind_pass_table);
    save("results_of_non_parallel_grouping.mat","results_of_non_parallel_grouping")
end
disp("Finished getting non parallel results")
%run parallel merge
if contains(all_files_in_dir,"results_of_parallel_grouping.mat")
    results_of_parallel_grouping = importdata(fullfile(dir_to_save_results_to,"results_of_parallel_grouping.mat"));
else
    results_of_parallel_grouping = determine_which_blind_pass_neurons_overlap_parallel(blind_pass_table,config);
    save("results_of_parallel_grouping.mat","results_of_parallel_grouping");
end
disp("Finished getting parallel results")

%now compare them to ensure that the groups are the same


cd(home_dir);

end