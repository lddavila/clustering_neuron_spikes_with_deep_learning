function [] = train_nn_to_predict_accuracy_based_on_mean_waveforms()
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%loading the config and setting the neural network name
config = spikesort_config();
which_nn = "hist_only_acc_cats";

%loading the blind pass table
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
parent_save_dir = config.parent_save_dir;
disp("Finished Loading Data")

dir_to_save_results_to = fullfile(parent_save_dir,"hist_only_acc_cats");
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating directory")

list_of_features_to_add = [" mean_waveform_rep_wire_1"," mean_waveform_rep_wire_2"," mean_waveform_rep_wire_3"," mean_waveform_rep_wire_4"];
[assembled_data] = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);

%get list of how many different combinations of the histogram feature you can have
max_num_hists = sum(contains(list_of_features_to_add,"histogram"));
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
what_combinations_of_hists_to_add = 1:size(table_of_all_hists,1);


%get a table which can be used to assemble all possible permutations of the meta data used
permutations_table = get_table_of_all_permutations_for_nn_training(["num_acc_cats", ...
    "num_layers", ...
    "filter_sizes", ...
    "which_hists"], ...
    number_of_accuracy_categories,number_of_layers,filter_sizes,what_combinations_of_hists_to_add);

%now assemble your training data sets based off of your desired permutations
filter_sizes_cell_array =  cell(size(permutations_table,1),1);
num_layers_cell_array =  cell(size(permutations_table,1),1);
training_sets = cell(size(permutations_table,1),1);
num_acc_cats_as_cell_array = cell(size(permutations_table,1),1);
place_counter = 1;
for j=number_of_accuracy_categories
    %get the accuracy category according to permutations
    table_with_accuracy = add_accuracy_col_on_hpc([],spikesort_config(),blind_pass_table(:,"accuracy"),j);
    subset_of_perms_table = permutations_table(permutations_table{:,"num_acc_cats"}==j,:);
   
    for i=1:size(subset_of_perms_table,1)
        %first check which histograms should be used
        which_hists_row = subset_of_perms_table{i,"which_hists"};
        which_hist_combination = table_of_all_hists{which_hists_row,"permutations_of_hists"}{1};

        hist_data = horzcat(assembled_data{which_hist_combination});

        num_layers_cell_array{place_counter} = subset_of_perms_table{i,"num_layers"};
        filter_sizes_cell_array{place_counter} = subset_of_perms_table{i,"filter_sizes"};
        %now add the accuracy category

        training_set_data = array2table([hist_data,table_with_accuracy{:,"accuracy_category"}]);
        %now remove any rows that may have produced nans
        training_set_data(isnan(training_set_data{:,end}),:) = [];
        training_sets{place_counter} = training_set_data;
        num_acc_cats_as_cell_array{place_counter} = j;
        disp(place_counter)
        place_counter = place_counter+1;
    end
end

%now train various neural networks based off of those datasets to detect which permutation of training data produced the highest accuracy
cd(dir_to_save_results_to);
parfor i=1:size(training_sets,1)
    [accuracy,net,layers] = predict_acc_cat_using_leaky_relu(training_sets{i},filter_sizes_cell_array{i},num_layers_cell_array{i});
    net_struct = struct();
    net_struct.net = net;
    net_struct.layers = layers;
    num_acc_cats = num_acc_cats_as_cell_array{i};
    save_name = sprintf('%.4f_accurate_%i_acc_cats_num_layers_%i_num_neur_pr_lyer_%i dataset %i',accuracy,num_acc_cats,num_layers_cell_array{i},filter_sizes_cell_array{i},i);
    par_save(save_name+".mat",net_struct);
end
cd(home_dir)
end