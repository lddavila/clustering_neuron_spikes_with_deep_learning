function [] = train_super_nn()
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
number_of_accuracy_categories = [4,5];
number_of_layers = 1:1:50;
filter_sizes = [5 10 15 20 25 30 35 40 50];
config = spikesort_config();


parent_save_dir = config.parent_save_dir;
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
disp("Finished loading the updated table of overlap")

size_col = cell2mat(cellfun(@size, blind_pass_table.timestamps, 'UniformOutput', false));
size_col = size_col(:,1);

%import the choose better nn
choose_better_nn_struct = importdata(config.FP_TO_COMPLEX_CHOOSE_BETTER_NN);
choose_better_nn = choose_better_nn_struct.net;

%import the accuracy category grades + universal rank predictor only neurons

%import the accuracy category mean waveform predictor

%import the number of under units predictor nn
nn_struct = importdata(config.FP_TO_Multi_under_units_predicting_nn);
multi_under_units_net = nn_struct.net;
%import the general accuracy cat neural network predictor

%import the verbose waveform accuracy category predictor

% import the neural network that has 4 accuracy categories and uses mean
% waveforms along with rank
nn_struct = importdata(config.FP_TO_4_accuracy_cats_predictor);
nn_4_accuracy_cats = nn_struct.net;




mean_waveform_var_names = contains(blind_pass_table.Properties.VariableNames,"mean_waveform_rep_wire");
all_mean_waveforms = cell2mat(blind_pass_table{:,mean_waveform_var_names});


which_nn = "super_nn";

[grade_names,all_grades]= flatten_grades_cell_array(blind_pass_table{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
grades_array = all_grades(:,indexes_of_grades_were_looking_for);

disp("Finished Flattening Grades")

% get the underunit predictions using the nn
under_unit_predictor = nan(size(blind_pass_table,1),1);
for i=1:size(blind_pass_table,1)
    data_for_nn = [grades_array(i,:),all_mean_waveforms(i,1:150)];
    class_pred = predict(multi_under_units_net,data_for_nn);
    [~,max_class] = max(class_pred);
    under_unit_predictor(i) = max_class-1;
end


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







for i=1:size(number_of_accuracy_categories,2)
    number_of_accuracy_cats = number_of_accuracy_categories(i);
    dir_to_save_accuracy_cat_to = fullfile(parent_save_dir,"super_nn_tests_num_acc_cats"+string(number_of_accuracy_cats));
    if ~exist(dir_to_save_accuracy_cat_to,"dir")
        dir_to_save_accuracy_cat_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_accuracy_cat_to);
    end
    cd(dir_to_save_accuracy_cat_to);
    list_of_files_in_current_directory = struct2table(dir(pwd));
    %get the predicted rank for each row in the blind pass table
    if ~any(contains(string(list_of_files_in_current_directory{:,"name"}),"blind_pass_table_with_rank.mat"))
        presorted_grade_rows = grades_array(presorted_table_rows,:);
        sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
        num_iterations = size(sliced_bp_table,1);
        parfor sliced_counter=1:size(blind_pass_table,1)
            current_data = sliced_bp_table{sliced_counter};
            estimated_rank_col(sliced_counter) = add_universal_rank(current_data{1,"mean_waveform_rep_wire_1"}{1},grades_array(sliced_counter,:),size(current_data{1,"timestamps"}{1},1),presorted_table,choose_better_nn, presorted_grade_rows, current_data{1,"timestamps"}{1},config);
            print_status_iter_message("train_accuracy_cat_prediction_nn_with_grades_and_universal_rank.m",sliced_counter,num_iterations);
        end
        blind_pass_table.rank = estimated_rank_col;
        save("blind_pass_table_with_rank.mat","blind_pass_table");
    else
        blind_pass_table = importdata("blind_pass_table_with_rank.mat");
    end

    %for each row in the blind pass table get the accuracy category prediction

    %add the class predictions for the 4 accuracy categories based on rank and
    %all waveforms
    accuracy_cat_pred = nan(size(blind_pass_table,1),1);
    parfor acc_cat_counter=1:size(blind_pass_table,1)
        %table_of_nn_data =array2table([grades_array(:,:),all_mean_waveforms(:,1:(number_of_mw_to_use*150)),blind_pass_table{:,"rank"}./100,table_with_accuracy{:,"accuracy_category"}]);
        nn_data = [grades_array(acc_cat_counter,:),all_mean_waveforms(acc_cat_counter,:),blind_pass_table{acc_cat_counter,"rank"}./100];
        nn_pred = predict(nn_4_accuracy_cats,nn_data);
        [~,class] = max(nn_pred);
        accuracy_cat_pred(acc_cat_counter) = class-1;
    end

    table_with_accuracy = add_accuracy_col_on_hpc([],spikesort_config(),blind_pass_table,number_of_accuracy_cats);
    data_for_nn = [grades_array(:,:),...
        all_mean_waveforms,...
        blind_pass_table{:,"rank"}./100,...
        blind_pass_table{:,"grades_pred"},...
        blind_pass_table{:,"mean_wave_pred"},...
        blind_pass_table{:,"Z Score"},...
        under_unit_predictor,...
        size_col,...
        accuracy_cat_pred,...
        ];

    %rescale the data
    col_min = min(data_for_nn,[],"omitnan");
    col_max = max(data_for_nn,[],"omitnan");
    data_for_nn =rescale(data_for_nn,-1,1,"InputMin",col_min,"InputMax",col_max);

    data_for_nn = [data_for_nn,table_with_accuracy{:,"accuracy_category"}];

    table_of_nn_data =array2table(data_for_nn);

    table_of_nn_data = rmmissing(table_of_nn_data);
    feature_names = [config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST),...
        "mean_waveform_1",...
        "mean_waveform_2",...
        "mean_waveform_3",...
        "mean_waveform_4",...
        "grades_and_rank_pred",...
        "mean_waveform_pred",...
        "z score",...
        "under unit prediction",...
        "size",...
        "4_acc_cat_predictor",...
        "actual_accuracy_category"];
    columns_belonging_to_features = [num2cell(1:size(config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST),2)),...
        19:18+(150*1),... %indexes of mean waveform 1
        169:318,... %indexes of mean waveform 2
        319:468,...%indexes of mean waveform 3
        469:618,... %indexes of mean waveform 4
        619,... %index of the rank
        620,... %prediction of grades +rank nn
        621,... %prediction of the mean waveform nn
        622,... %index of the z score
        623,... %index of the under unit predicting nn
        624,... %index of the cluster size
        625,... %index of the 4 accuracy category predictor
        626, %index of the actual accuracy category
        ];

    feature_tables = {};
    list_of_features = {};
    extra_feautre_counter = 1;
    for k=19:size(feature_names,2)-1
        all_possible_combos_of_extra_features= nchoosek(19:size(feature_names,2)-1,extra_feautre_counter);
        all_possible_combos_of_extra_features = [repmat(1:18,size(all_possible_combos_of_extra_features,1),1),all_possible_combos_of_extra_features];
        for j=1:size(all_possible_combos_of_extra_features,1)
            feature_tables{end+1} =table_of_nn_data(:,[cell2mat(columns_belonging_to_features(all_possible_combos_of_extra_features(j,:))),626]) ;
            list_of_features{end+1} = feature_names(all_possible_combos_of_extra_features(j,:));
        end
        extra_feautre_counter = extra_feautre_counter+1;
    end


    for table_counter=1:size(feature_tables,2)

        list_of_files_in_current_directory = struct2table(dir(fullfile(pwd,"*.mat")));
        list_of_files_in_current_directory = string(list_of_files_in_current_directory{:,"name"});

        for j=1:size(number_of_layers,2)
            num_layers = number_of_layers(j);
            for k=1:size(filter_sizes,2)
                num_neurons = filter_sizes(k);
                beginning_time = tic;
                final_parts_of_save_name ="_num_layers "+string(num_layers)+ "_num_neur_layer"+string(num_neurons)+ "_"+which_nn +"_tbl_"+string(table_counter);
                if any(contains(list_of_files_in_current_directory,final_parts_of_save_name))
                    continue;
                end
                [accuracy_score,net,~]=predict_acc_cat_using_leaky_relu(table_of_nn_data,num_neurons,num_layers);
                end_time = toc(beginning_time);
                % disp("Projected end time:"+string(currentDateTime+end_time));

                disp("The last iteration took "+string(end_time)+" seconds")
                name_to_save_under = "accuracy_score "+string(accuracy_score)+final_parts_of_save_name;

                net_struct = struct();
                net_struct.Layers = net.Layers;
                net_struct.Connections = net.Connections;
                net_struct.net = net;
                net_struct.feature_names = {list_of_features{table_counter}};
                par_save(name_to_save_under+".mat",net_struct);
            end
        end
    end
    cd("..");
end
cd(home_dir);
end