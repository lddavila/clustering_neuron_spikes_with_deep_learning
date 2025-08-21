function [] = test_parallel_vs_non_parallel()
clc;
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
if any(contains(all_files_in_dir,"results_of_non_parallel_grouping.mat"))
    results_of_non_parallel_grouping = importdata(fullfile(dir_to_save_results_to,"results_of_non_parallel_grouping.mat"));
else
    results_of_non_parallel_grouping = determine_which_blind_pass_neurons_overlap(blind_pass_table,config);
    save("results_of_non_parallel_grouping.mat","results_of_non_parallel_grouping")
end
disp("Finished getting non parallel results")
%run parallel merge
if any(contains(all_files_in_dir,"results_of_parallel_grouping.mat"))
    results_of_parallel_grouping = importdata(fullfile(dir_to_save_results_to,"results_of_parallel_grouping.mat"));
else
    results_of_parallel_grouping = determine_which_blind_pass_neurons_overlap_parallel(blind_pass_table,config);
    save("results_of_parallel_grouping.mat","results_of_parallel_grouping");
end
disp("Finished getting parallel results")

%now compare them to ensure that the groups are the same

%step 1:
% ensure that they have the same number of items in the array
if size(results_of_parallel_grouping,2) ~= size(results_of_non_parallel_grouping,2)
    error("Parallel and non parallel do not have the same number of groups");
end

%step 2:
%ensure that all the groups are the same size
for i=1:size(results_of_parallel_grouping,2)
    current_par_data = results_of_parallel_grouping{i};
    current_seq_data = results_of_non_parallel_grouping{i};
    if size(current_seq_data,1) ~= size(current_par_data)
        disp(current_seq_data);
        disp(current_par_data);
        disp("Seq Data Size")
        disp(size(current_seq_data));
        disp("Par Data Size")
        disp(size(current_par_data));
        error(sprintf("Group %i have different number of elements",i));
    end
end

%step 3:
%ensure that all groups have the same members
for i=1:size(results_of_parallel_grouping,2)
    current_par_data = results_of_parallel_grouping{i};
    current_seq_data = results_of_non_parallel_grouping{i};
    in_parallel_string = string(current_par_data{:,"Z Score"}) +string(current_par_data{:,"Tetrode"})+string(current_par_data{:,"Cluster"});
    in_seq_string = string(current_seq_data{:,"Z Score"}) +string(current_seq_data{:,"Tetrode"})+string(current_seq_data{:,"Cluster"});
    have_same_members = ismember(in_parallel_string,in_seq_string);

    if ~all(have_same_members)
        fprintf('Sequential Groups %i has the following memeber that parallel groups do not %i',i,i)
        disp(current_seq_data(have_same_members,:))
        errror('Group %i do not have same members',i)
    end
end
disp("Your parallel and sequential groups are identical")
cd(home_dir);





end