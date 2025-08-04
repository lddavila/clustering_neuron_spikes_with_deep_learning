function [] = train_accuracy_cat_prediction_nn_with_grades_and_universal_rank()
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
number_of_accuracy_categories = [3];
number_of_layers = 1:1:50;
filter_sizes = [5 10 15 20 25 30 35 40 50];
accuracy_array = cell(length(number_of_accuracy_categories),1);
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
presorted_grade_rows = grades_array(presorted_table_rows,:);
for i=1:size(blind_pass_table,1)
    estimated_rank_col(i) = add_universal_rank(blind_pass_table{i,"Mean Waveform"}{1},grades_array(i,:),size(blind_pass_table{i,"timestamps"}{1},1),presorted_table,choose_better_nn, presorted_grade_rows, blind_pass_table{i,"timestamps"}{1},config);
    %                       add_universal_rank(current_data_waveform,                 current_data_grades,current_data_size,                        presorted_table,choose_better_nn, presorted_grade_rows,current_ts,config)
    print_status_iter_message("train_accuracy_cat_prediction_nn_with_grades_and_universal_rank.m",i,size(blind_pass_table,1));
end


blind_pass_table.rank = estimated_rank_col;


for i=1:size(number_of_accuracy_categories,2)
    number_of_accuracy_cats = number_of_accuracy_categories(i);
    table_with_accuracy = add_accuracy_col_on_hpc([],spikesort_config(),blind_pass_table,number_of_accuracy_cats);
    table_of_nn_data =array2table([grades_array(:,:),estimated_rank_col./100,table_with_accuracy{:,"accuracy_category"}]);
    table_of_nn_data = rmmissing(table_of_nn_data);
    for j=1:size(number_of_layers,2)
        num_layers = number_of_layers(j);
        for k=1:size(filter_sizes,2)
            num_neurons = filter_sizes(k);

            beginning_time = tic;
            [accuracy_score,net,~]=predict_acc_cat_using_leaky_relu(table_of_nn_data,num_neurons,num_layers);
            end_time = toc(beginning_time);
            % disp("Projected end time:"+string(currentDateTime+end_time));

            disp("The last iteration took "+string(end_time)+" seconds")
            name_to_save_under = "accuracy score "+string(accuracy_score)+"number of acc cats " +string(number_of_accuracy_cats)+" num layers "+string(num_layers)+ " num neurons per layer"+string(num_neurons)+ " "+which_nn;
            fileID = fopen(name_to_save_under+ ".txt",'w');
            fclose(fileID);
            net_struct = struct();
            net_struct.Layers = net.Layers;
            net_struct.Connections = net.Connections;
            net_struct.net = net;
            save(name_to_save_under+".mat","-fromstruct",net_struct)
        end
    end
end
cd(home_dir);
end