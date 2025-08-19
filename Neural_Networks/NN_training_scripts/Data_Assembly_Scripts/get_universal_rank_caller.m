function [estimated_rank_col] = get_universal_rank_caller(blind_pass_table,config)
choose_better_nn_struct = importdata(config.FP_TO_COMPLEX_CHOOSE_BETTER_NN);
choose_better_nn = choose_better_nn_struct.net;
grades_array = flatten_grades_caller(blind_pass_table,config);
presorted_table = cell(100,1);
presorted_table_rows = nan(size(presorted_table,1),1);
rng(0);

for j=1:1:100
    lower_bound = j-1;
    upper_bound = j;
    [rows_in_boundary,~] = find(blind_pass_table{:,"accuracy"}<= upper_bound & blind_pass_table{:,"accuracy"} > lower_bound);
    presorted_table_rows(j) = rows_in_boundary(randperm(size(rows_in_boundary,1),1));
    presorted_table{j}= blind_pass_table(presorted_table_rows(j),:);
end
presorted_grade_rows = grades_array(presorted_table_rows,:);
presorted_table = vertcat(presorted_table{:});
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
sliced_grades = slice_table_for_parallel_processing(grades_array,[]);
q = parallel.pool.DataQueue;
afterEach(q,@print_message_using_dataqueue)
print_message_using_dataqueue(size(blind_pass_table,1),"get_universal_rank_caller.m");
estimated_rank_col = nan(size(blind_pass_table,1),1);
parfor j=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{j};
    estimated_rank_col(j) = add_universal_rank(current_data{1,"Mean Waveform"}{1},sliced_grades{j},size(current_data{1,"timestamps"}{1},1),presorted_table,choose_better_nn, presorted_grade_rows, current_data{1,"timestamps"}{1},config);
    send(q,[]);
end
end