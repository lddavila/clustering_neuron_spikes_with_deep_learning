function [] = train_nn_with_wf_hists_and_grades()
clc;
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%loading the config and setting the neural network name
config = spikesort_config();
which_nn = "wave_and_hist";

%loading the blind pass table
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
parent_save_dir = config.parent_save_dir;
disp("Finished Loading Data")

dir_to_save_results_to = fullfile(parent_save_dir,"waves_hists_and_scaling");
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating directory")


list_of_features_to_add = ["histogram 1","histogram 2","histogram 3","histogram 4","mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","size","grades"];
[assembled_data] = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);

%get list of how many different combinations of the histogram feature you can have
max_num_hists = sum(contains(list_of_features_to_add,"histogram"));
table_of_all_hists = [];
parfor i=1:max_num_hists
    all_possible_combinations = nchoosek(1:max_num_hists,i);
    all_possible_combinations = num2cell(all_possible_combinations,2);
    table_of_all_hists = [table_of_all_hists;table(all_possible_combinations,'VariableNames',["permutations_of_hists"])];
end


%get list of how many different combinations of the waveforms feature you can have
max_num_waveforms = sum(contains(list_of_features_to_add,"mean_waveform"));
table_of_all_waveforms = [];
parfor i=1:max_num_waveforms
    all_possible_combinations = nchoosek(1:max_num_waveforms,i);
    all_possible_combinations = num2cell(all_possible_combinations,2);
    table_of_all_waveforms = [table_of_all_waveforms;table(all_possible_combinations,'VariableNames',["permutations_of_waveforms"])];
end

%get a list of how many different ways you can combimbe waveforms and
%histograms
array_of_all_mean_wf_and_hist_combos = combvec(1:size(table_of_all_waveforms,1),1:size(table_of_all_hists,1)).';

%set some hyperparameters for the series of trainings we will be doing
number_of_accuracy_categories = [3,4,5];
number_of_layers = 1:15;
filter_sizes = 5:5:20;
num_mean_wave_and_hist_combos = 1:size(array_of_all_mean_wf_and_hist_combos);

%get a table which tells you all possible permutations of the training sets
%you wish to create
permutations_table = get_table_of_all_permutations_for_nn_training(["num_acc_cats", ...
    "num_layers", ...
    "filter_sizes", ...
    "which_hists_and_waves"], ...
    number_of_accuracy_categories,number_of_layers,filter_sizes,num_mean_wave_and_hist_combos);



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
        %first get the row which determines which waveform and histogram
        %combination will be used
        which_waveform_and_histogram= subset_of_perms_table{i,"which_hists_and_waves"};

        %first select which waveform(s) will be used for this training set
        which_waveforms_row = array_of_all_mean_wf_and_hist_combos(which_waveform_and_histogram,1);
        which_waveform_combination = table_of_all_waveforms{which_waveforms_row,"permutations_of_waveforms"}{1};
        idxs_with_wf = contains(list_of_features_to_add,"mean_waveform");
        only_waveforms_from_assembled_data = assembled_data(idxs_with_wf);
        waveform_data = horzcat(only_waveforms_from_assembled_data{which_waveform_combination});

        %now select which histogram(s) will be used for this training set
        which_histograms_row = array_of_all_mean_wf_and_hist_combos(which_waveform_and_histogram,2);
        which_histogram_combination = table_of_all_hists{which_histograms_row,"permutations_of_hists"}{1};
        only_hists_from_assembled_data = assembled_data(contains(list_of_features_to_add,"histogram"));
        hist_data = horzcat(only_hists_from_assembled_data{which_histogram_combination});

        num_layers_cell_array{place_counter} = subset_of_perms_table{i,"num_layers"};
        filter_sizes_cell_array{place_counter} = subset_of_perms_table{i,"filter_sizes"};

        %now normalize the grade data
        grades_data = normalize_data(assembled_data(contains(list_of_features_to_add,"grades")),-1,1);
        grades_data = grades_data{1};

        size_data =assembled_data{contains(list_of_features_to_add,"size")}; 

        training_set_data = array2table([waveform_data,hist_data,grades_data,size_data,table_with_accuracy{:,"accuracy_category"}]);
        %now remove any rows that may have produced nans
        training_set_data(isnan(training_set_data{:,end}),:) = [];
        training_sets{place_counter} = training_set_data;
        num_acc_cats_as_cell_array{place_counter} = j;
        if mod(place_counter,1000)==0
            disp(place_counter)
        end
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