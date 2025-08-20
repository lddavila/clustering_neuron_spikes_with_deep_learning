function [] = train_nn_to_see_more_gradience()
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%loading the config and setting the neural network name
config = spikesort_config();
which_nn = "dyn_sc_nn";

%loading the blind pass table
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
parent_save_dir = config.parent_save_dir;
disp("Finished Loading Data")

dir_to_save_results_to = fullfile(parent_save_dir,"dyn_scaling");
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating directory")

list_of_features_to_add = ["size","grades","mean waveform","histograms","universal_rank"];
list_of_features_to_add = ["size","grades","mean waveform","histograms"];
[assembled_data] = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);

%get list of how many different combinations of the histogram feature you can have
max_num_hists = size(assembled_data{4},2);
table_of_all_hists = [];
parfor i=1:max_num_hists
    all_possible_combinations = nchoosek(1:max_num_hists,i);
    all_possible_combinations = num2cell(all_possible_combinations,2);
    table_of_all_hists = [table_of_all_hists;table(all_possible_combinations,'VariableNames',["permutations_of_hists"])];
end

%get all combinations of normalizations that can be performed
%a feature is either normalized or it is not 
%therefore if you have 2 features then your possible normalizations are
%[0 0;
% 0 1;
% 1 0;
% 1 1]
%for 3 features you would get even more normalization combinations
%increases at a rate of 2^n
binary_rep = repmat({[0,1]},1,size(list_of_features_to_add,2));
all_normalization_combinations = combvec(binary_rep{:}).';

%set some hyperparameters for the series of trainings we will be doing
number_of_accuracy_categories = [3,4];
number_of_layers = 1:15;
filter_sizes = 5:5:20;
which_features_to_use = 1:size(list_of_features_to_add,2);
what_combinations_of_hists_to_add = 1:size(table_of_all_hists,1);
what_normalization_to_use = 1:size(all_normalization_combinations);

%get a table which can be used to assemble all possible permutations of the meta data used
permutations_table = get_table_of_all_permutations_for_nn_training(["num_acc_cats", ...
    "num_layers", ...
    "filter_sizes", ...
    "which_features_to_use", ...
    "which_hists", ...
    "whats_normalized"], ...
    number_of_accuracy_categories,number_of_layers,filter_sizes,which_features_to_use,what_combinations_of_hists_to_add,what_normalization_to_use);

%now assemble your training data sets based off of your desired permutations
training_sets = cell(size(permutations_table,1),1);
for i=1:size(permutations_table,1)
    %first we will check which features should be normalized 
    which_normalization_schema_to_use = permutations_table{i,"whats_normalized"};
    what_should_be_normalized = all_normalization_combinations(which_normalization_schema_to_use,:);

    %next normalize what must be normalized
    [normalized_data,cell_array_of_col_min,cell_array_of_col_max] = normalize_data(assembled_data(what_should_be_normalized),-1,1);

    if ~isnan(normalized_data)
    else
        
    end


    current_parameters = {permutations_table{i,"num_layers"},permutations_table{i,"filter_sizes"}};
    training_sets{i} = current_parameters;
end

%now train various neural networks based off of those datasets to detect which permutation of training data produced the highest accuracy 
%predict_acc_cat_using_leaky_relu(transformed_data,permutations_table{i,"filter_sizes"},permutations_table{i,"num_layers"});
end