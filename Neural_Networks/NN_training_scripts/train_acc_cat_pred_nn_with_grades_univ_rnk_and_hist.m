function [] = train_acc_cat_pred_nn_with_grades_univ_rnk_and_hist()
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
number_of_accuracy_categories = [3,4];
number_of_layers = 1:1:50;
filter_sizes = [5 10 15 20 25 30 35 40 50];
config = spikesort_config();


parent_save_dir = config.parent_save_dir;
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
choose_better_nn_struct = importdata(config.FP_TO_COMPLEX_CHOOSE_BETTER_NN);


choose_better_nn = choose_better_nn_struct.net;
disp("Finished loading the updated table of overlap")

dir_to_save_accuracy_cat_to = fullfile(parent_save_dir,"acc_cats_with_hist");
if ~exist(dir_to_save_accuracy_cat_to,"dir")
    dir_to_save_accuracy_cat_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_accuracy_cat_to);
end



cd(dir_to_save_accuracy_cat_to);
which_nn = "acc_cats_with_hist";

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

%get the histograms for each row of blind pass table
all_hists = vertcat(blind_pass_table{:,"grades"}{:});
all_hists = all_hists(:,64);
possible_permutations ={};
for i=1:size(all_hists{1},1)
    possible_permutations{end+1} =nchoosek(1:size(all_hists{1},1),i);
end

presorted_table = vertcat(presorted_table{:});
presorted_grade_rows = grades_array(presorted_table_rows,:);
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
sliced_grades = slice_table_for_parallel_processing(grades_array,[]);
q = parallel.pool.DataQueue;
afterEach(q,@print_message_using_dataqueue)
print_message_using_dataqueue(size(blind_pass_table,1),"train_acc_cat_pred_nn_with_grades_unv_rnk_and_hist.m getting rank");
parfor i=1:size(blind_pass_table,1)
    current_data = sliced_bp_table{i};
    estimated_rank_col(i) = add_universal_rank(current_data{1,"Mean Waveform"}{1},sliced_grades{i},size(current_data{1,"timestamps"}{1},1),presorted_table,choose_better_nn, presorted_grade_rows, current_data{1,"timestamps"}{1},config);
    send(q,[]);
end


blind_pass_table.rank = estimated_rank_col;


for current_perm =1:size(possible_permutations,1)
    for which_hists =1:size(possible_permutations{current_perm},1)
        hists_to_use = possible_permutations{current_perm}(which_hists,:);
        sample_left_hists = all_hists;
        hist_data = cell2mat(cellfun(@(m) reshape(m(hists_to_use,:),1,[]),sample_left_hists, 'UniformOutput', false));
        for i=1:size(number_of_accuracy_categories,2)
            number_of_accuracy_cats = number_of_accuracy_categories(i);
            table_with_accuracy = add_accuracy_col_on_hpc([],spikesort_config(),blind_pass_table,number_of_accuracy_cats);
            table_of_nn_data =array2table([grades_array(:,:),estimated_rank_col./100,hist_data,table_with_accuracy{:,"accuracy_category"}]);
            table_of_nn_data = rmmissing(table_of_nn_data);
            for j=1:size(number_of_layers,2)
                num_layers = number_of_layers(j);
                for k=1:size(filter_sizes,2)
                    normalize_or_dont_possibilities = [1,0];
                    for normalize_or_dont=normalize_or_dont_possibilities
                        if normalize_or_dont
                            to_add = "_normalized";
                            altered_data = table2array(table_of_nn_data);
                            col_min = min(altered_data);
                            col_max = max(altered_data);
                            altered_data = rescale(altered_data,-1,1,"InputMax",col_max,"InputMin",col_min);
                            final_nn_data = array2table(altered_data);
                        else
                            to_add = "";
                            final_nn_data = table_of_nn_data;
                        end
                        num_neurons = filter_sizes(k);

                        beginning_time = tic;
                        [accuracy_score,net,~]=predict_acc_cat_using_leaky_relu(final_nn_data,num_neurons,num_layers);
                        end_time = toc(beginning_time);
                        % disp("Projected end time:"+string(currentDateTime+end_time));

                        disp("The last iteration took "+string(end_time)+" seconds")
                        name_to_save_under = "acc_sc_"+string(accuracy_score)+"_num_acc_cats_" +string(number_of_accuracy_cats)+"_num_lay_"+string(num_layers)+ "_num_neur_per_lay"+string(num_neurons)+ "_"+which_nn+to_add;
                        net_struct = struct();
                        net_struct.Layers = net.Layers;
                        net_struct.Connections = net.Connections;
                        net_struct.net = net;
                        net_struct.which_hists = hists_to_use;
                        if normalize_or_dont
                            net_struct.feature_min = col_min;
                            net_struct.feature_max = col_max;
                            net_struct.feature_bounds = [-1,1]; 
                        end
                        par_save(name_to_save_under+".mat",net_struct)
                    end
                end
            end
        end
    end
end
cd(home_dir);
end