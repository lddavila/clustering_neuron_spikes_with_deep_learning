function [] = acc_cat_pred_with_gr_univ_rank_and_mult_waves()
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
number_of_accuracy_categories = [3,4];
number_of_layers = 1:1:50;
filter_sizes = [5 10 15 20 25 30 35 40 50];
config = spikesort_config();

if config.ON_HPC
    parent_save_dir = config.parent_save_dir_ON_HPC;
    blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS_ON_HPC);
    choose_better_nn_struct = config.FP_TO_COMPLEX_CHOOSE_BETTER_NN_ON_HPC;
else
    parent_save_dir = config.parent_save_dir;
    blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
    choose_better_nn_struct = importdata(config.FP_TO_COMPLEX_CHOOSE_BETTER_NN);
end

choose_better_nn = choose_better_nn_struct.net;
disp("Finished loading the updated table of overlap")

dir_to_save_accuracy_cat_to = fullfile(parent_save_dir,config.DIR_TO_SAVE_RESULTS_TO);
if ~exist(dir_to_save_accuracy_cat_to,"dir")
    dir_to_save_accuracy_cat_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_accuracy_cat_to);
end

mean_waveform_var_names = contains(blind_pass_table.Properties.VariableNames,"mean_waveform_rep_wire");
all_mean_waveforms = cell2mat(blind_pass_table{:,mean_waveform_var_names});

cd(dir_to_save_accuracy_cat_to);
which_nn = config.WHICH_NEURAL_NET;

[grade_names,all_grades]= flatten_grades_cell_array(blind_pass_table{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
grades_array = all_grades(:,indexes_of_grades_were_looking_for);

disp("Finished Flattening Grades")


% data_for_nn = [mean_waveform_array(all_possible_combos(random_indexes,1),:),...
%     grades_array(all_possible_combos(random_indexes,1),:),...
%     mean_waveform_array(all_possible_combos(random_indexes,2),:),...
%     grades_array(all_possible_combos(random_indexes,2),:),...
%     random_sample_indexes,...
%     left_is_better_col];

%overlap_col = get_overlap_percentage_for_nn_training_data(blind_pass_table,remaining_idxs,config);


% table_of_nn_data = array2table([shuffled_data_for_nn(:,1:end-1),overlap_col,first_size_col(:,1),sec_size_col(:,1),shuffled_data_for_nn(:,end)]);


estimated_rank_col = nan(size(blind_pass_table,1),1);

% add a smarter version of the sorted table
presorted_table = cell(100,1);
presorted_table_rows = nan(size(presorted_table,1),1);
rng(0);
for i=1:1:100
    lower_bound = i-1;
    upper_bound = i;
    [rows_in_boundary,~] = find(blind_pass_table{:,"accuracy"}<= upper_bound & blind_pass_table{:,"accuracy"} > lower_bound);
    presorted_table_rows(i) = rows_in_boundary(randperm(size(rows_in_boundary,1),1));
    presorted_table{i}= blind_pass_table(presorted_table_rows(i),:);
end

presorted_table = vertcat(presorted_table{:});
list_of_files_in_current_directory = struct2table(dir(pwd));
if ~any(contains(string(list_of_files_in_current_directory{:,"name"}),"blind_pass_table_with_rank.mat"))
    presorted_grade_rows = grades_array(presorted_table_rows,:);
    sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
    num_iterations = size(sliced_bp_table,1);
    parfor i=1:size(blind_pass_table,1)
        current_data = sliced_bp_table{i};
        estimated_rank_col(i) = add_universal_rank(current_data{1,"Mean Waveform"}{1},grades_array(i,:),size(current_data{1,"timestamps"}{1},1),presorted_table,choose_better_nn, presorted_grade_rows, current_data{1,"timestamps"}{1},config);
        print_status_iter_message("train_accuracy_cat_prediction_nn_with_grades_and_universal_rank.m",i,num_iterations);
    end


    blind_pass_table.rank = estimated_rank_col;

    save("blind_pass_table_with_rank.mat","blind_pass_table");
else
    blind_pass_table = importdata("blind_pass_table_with_rank.mat");
end




possible_number_of_mean_waveforms_to_use = [3,4];
for number_of_mw_to_use=possible_number_of_mean_waveforms_to_use
    for i=1:size(number_of_accuracy_categories,2)
        number_of_accuracy_cats = number_of_accuracy_categories(i);


        table_with_accuracy = add_accuracy_col_on_hpc([],spikesort_config(),blind_pass_table,number_of_accuracy_cats);
        table_of_nn_data =array2table([grades_array(:,:),all_mean_waveforms(:,1:(number_of_mw_to_use*150)),blind_pass_table{:,"rank"}./100,table_with_accuracy{:,"accuracy_category"}]);
        to_add = "_used_"+string(number_of_mw_to_use)+"mw";

        table_of_nn_data = rmmissing(table_of_nn_data);
        for j=1:size(number_of_layers,2)
            num_layers = number_of_layers(j);
            parfor k=1:size(filter_sizes,2)
                num_neurons = filter_sizes(k);

                beginning_time = tic;
                [accuracy_score,net,~]=predict_acc_cat_using_leaky_relu(table_of_nn_data,num_neurons,num_layers);
                end_time = toc(beginning_time);
                % disp("Projected end time:"+string(currentDateTime+end_time));

                disp("The last iteration took "+string(end_time)+" seconds")
                name_to_save_under = "accuracy_score "+string(accuracy_score)+"num_acc_cats_" +string(number_of_accuracy_cats)+"_num_layers "+string(num_layers)+ "_num_neur_layer"+string(num_neurons)+to_add+ "_"+which_nn;
              
                net_struct = struct();
                net_struct.Layers = net.Layers;
                net_struct.Connections = net.Connections;
                net_struct.net = net;
                par_save(name_to_save_under,net_struct);
            end
        end
    end
end
cd(home_dir);
end