function [blind_pass_table] = add_accuracy_cat_pred_from_nn(blind_pass_table,config)
acc_pred_nn_struct = importdata(config.FP_TO_GRADES_ACC_PRED_WITH_RANK_NN);
acc_pred_nn = acc_pred_nn_struct.net;
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
presorted_table = importdata(config.FP_TO_PRESORTED_TABLE);

% presorted_grade_rows_unformatted = vertcat(presorted_table{:,"grades"}{:});
% presorted_grade_rows = cell2mat(presorted_grade_rows_unformatted(:,config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST));


%get grades from each row
[grade_names,presorted_grades]= flatten_grades_cell_array(presorted_table{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
presorted_grade_rows= presorted_grades(:,indexes_of_grades_were_looking_for);


estimated_rank_col = nan(size(blind_pass_table,1),1);
choose_better_nn_struct = importdata(config.FP_TO_COMPLEX_CHOOSE_BETTER_NN);
choose_better_nn = choose_better_nn_struct.net;
num_iterations = size(sliced_bp_table,1);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"add_accuracy_cat_prediction_from_nn: getting rank.m")

%parallel_constant_config = parallel.pool.Constant(config);
presorted_table_constant = parallel.pool.Constant(presorted_table);


parfor i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    current_data_waveform = current_data{1,"mean_waveform_rep_wire_1"}{1};
    %current_data_grades_unformatted = current_data{1,"grades"}{1};
    %current_data_grades = cell2mat(current_data_grades_unformatted(parallel_constant_config.Value.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST));

    [~,current_data_grades] = flatten_grades_cell_array(current_data{:,"grades"},config);
    current_data_grades =current_data_grades(indexes_of_grades_were_looking_for);
    current_data_size = size(current_data{1,"timestamps"}{1},1);
    current_ts = current_data{1,"timestamps"}{1};
    estimated_rank_col(i) = add_universal_rank(current_data_waveform,current_data_grades,current_data_size,presorted_table_constant.Value,choose_better_nn,presorted_grade_rows,current_ts,config);
    % print_status_iter_message("add_accuracy_cat_pred_from_nn:first parfor",i,num_iterations);
    send(q,[]);
end

accuracy_categories = nan(size(blind_pass_table,1),1);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"add_accuracy_cat_prediction_from_nn: getting accuracy cat prediction.m")
%now predict the accuracy category for the current neural network
parfor i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    [~,current_data_grades] = flatten_grades_cell_array(current_data{:,"grades"},config);
    current_data_grades = current_data_grades(:,indexes_of_grades_were_looking_for);
    class_probabilities = predict(acc_pred_nn,[current_data_grades,estimated_rank_col(i)]);
    [~,acc_category] = max(class_probabilities);
    accuracy_categories(i) = acc_category-1;
    send(q,[]);
end
% Store the accuracy categories back into the blind_pass_table
blind_pass_table.("grades_pred") = accuracy_categories;
end