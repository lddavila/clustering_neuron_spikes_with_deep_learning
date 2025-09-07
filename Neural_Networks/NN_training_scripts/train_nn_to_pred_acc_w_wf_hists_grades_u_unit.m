function [] = train_nn_to_pred_acc_w_wf_hists_grades_u_unit()
clc;
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%loading the config and setting the neural network name
config = spikesort_config();
which_nn = "waves_hist_uu_acc_cats";

%loading the blind pass table
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
parent_save_dir = config.parent_save_dir;
disp("Finished Loading Data")

dir_to_save_results_to = fullfile(parent_save_dir,"waves_hist_uu_5_acc_cats");
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating directory")


list_of_features_to_add = ["histogram 1","histogram 2","histogram 3","histogram 4",...
    "mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4",...
    "size",...
    "grades",...
    "under_unit_1_10","under_unit_2_10","under_unit_3_10","under_unit_4_10","under_unit_5_10",...
    "under_unit_1_5","under_unit_2_5","under_unit_3_5","under_unit_4_5","under_unit_5_5",...
    "under_unit_1_15","under_unit_2_15","under_unit_3_15","under_unit_4_15","under_unit_5_15",...
    "under_unit_1_20","under_unit_2_20","under_unit_3_20","under_unit_4_20","under_unit_5_20"];
%"under_unit_gradienceLevelN_minThresholdM";
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

%get a list of all underunit datasets you can use
idxs_of_under_unit = find(contains(list_of_features_to_add,"under_unit"));

%get a list of how many different ways you can combimbe waveforms and
%histograms
array_of_all_mean_wf_and_hist_combos = combvec(1:size(table_of_all_waveforms,1),1:size(table_of_all_hists,1)).';

%set some hyperparameters for the series of trainings we will be doing
number_of_accuracy_categories = [5];
number_of_layers = 1:15;
filter_sizes = 5:5:20;
num_mean_wave_and_hist_combos = 1:size(array_of_all_mean_wf_and_hist_combos);
which_u_unit_data_to_use = idxs_of_under_unit;

%get a table which tells you all possible permutations of the training sets
%you wish to create
permutations_table = get_table_of_all_permutations_for_nn_training(["num_acc_cats", ...
    "num_layers", ...
    "filter_sizes", ...
    "which_hists_and_waves","which_under_unit_data"], ...
    number_of_accuracy_categories,number_of_layers,filter_sizes,num_mean_wave_and_hist_combos,which_u_unit_data_to_use);


number_of_batches_required_to_run_all_permutations = ceil(size(permutations_table,1) / 40); %where 40 is the number of workers available AKA how many neural networks can be trained at once
%now assemble your training data sets based off of your desired permutations

disp("Beginning training set assembly");
cd(dir_to_save_results_to);
permutations_table_counter = 1;
for k=1:number_of_batches_required_to_run_all_permutations
    place_counter = 1;
    filter_sizes_cell_array =  cell(40,1);
    num_layers_cell_array =  cell(40,1);
    num_acc_cats_as_cell_array = cell(40,1);
    which_row_in_perms_table = cell(40,1);

    training_sets = cell(40,1);
    for i=(k-1)*40 + 1:min(k*40, height(permutations_table))
        %get the accuracy categories for the current training set
        table_with_accuracy = add_accuracy_col_on_hpc([],spikesort_config(),blind_pass_table(:,"accuracy"),permutations_table{i,"num_acc_cats"});

        %first get the row which determines which waveform and histogram
        %combination will be used
        which_waveform_and_histogram= permutations_table{i,"which_hists_and_waves"};

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

        num_layers_cell_array{place_counter} = permutations_table{i,"num_layers"};
        filter_sizes_cell_array{place_counter} = permutations_table{i,"filter_sizes"};

        %now normalize the grade data
        [grades_data,cell_array_of_col_min,cell_array_of_col_max]= normalize_data(assembled_data(contains(list_of_features_to_add,"grades")),-1,1);
        grades_data = grades_data{1};

        size_data =assembled_data{contains(list_of_features_to_add,"size")};

        %now get which_under_unit_data_to_use
        under_unit_data = assembled_data{permutations_table{permutations_table_counter,"which_under_unit_data"}};

        training_set_data = array2table([waveform_data,hist_data,grades_data,size_data,under_unit_data,table_with_accuracy{:,"accuracy_category"}]);

        %now remove any rows that may have produced nans
        training_set_data(isnan(training_set_data{:,end}),:) = [];
        training_sets{place_counter} = training_set_data;
        num_acc_cats_as_cell_array{place_counter} = permutations_table{i,"num_acc_cats"};
        if mod(place_counter,40)==0
            disp("Finished Data Assembly")
        end
        which_row_in_perms_table{place_counter} = permutations_table_counter;
        place_counter = place_counter+1;
        permutations_table_counter = permutations_table_counter+1;
    end

    %now train various neural networks based off of those datasets to detect which permutation of training data produced the highest accuracy
    parfor j=1:size(training_sets,1)
        [accuracy,net,layers] = predict_acc_cat_using_leaky_relu(training_sets{j},filter_sizes_cell_array{j},num_layers_cell_array{j});
        net_struct = struct();
        net_struct.net = net;
        net_struct.layers = layers;
        net_struct.normalization_col_min =cell_array_of_col_min;
        net_struct.normalization_col_max = cell_array_of_col_max;
        net_struct.normalization_bounds = [-1 1];
        num_acc_cats = num_acc_cats_as_cell_array{j};
        save_name = sprintf('%.4f_accurate_%i_acc_cats_num_layers_%i_num_neur_pr_lyer_%i dataset %i',accuracy,num_acc_cats,num_layers_cell_array{j},filter_sizes_cell_array{j},which_row_in_perms_table{j});
        par_save(save_name+".mat",net_struct);
    end
    clear("training_sets");
end




cd(home_dir)
end