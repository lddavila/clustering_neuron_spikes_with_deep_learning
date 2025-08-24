function [] = test_grouping_on_50_unit_example()
clc;
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%loading the config and setting the neural network name
config = spikesort_config();


%loading the blind pass table
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
parent_save_dir = config.parent_save_dir;
disp("Finished Loading Data")

dir_to_save_results_to = fullfile(parent_save_dir,"grouping_50_unit_example");
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating directory")

blind_pass_table_only_neurons = blind_pass_table(blind_pass_table{:,"is_neuron"}==1,:);
blind_pass_table_only_neurons_filt = blind_pass_table_only_neurons(blind_pass_table_only_neurons{:,"grades_pred"}>0,:);
determine_which_blind_pass_neurons_overlap_parallel(blind_pass_table_only_neurons_filt,spikesort_config)

end