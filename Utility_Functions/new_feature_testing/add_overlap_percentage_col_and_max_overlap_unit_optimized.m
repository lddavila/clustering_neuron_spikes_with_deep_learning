function [blind_pass_table] = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,config,timestamps)
% spikesort_config

sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
ground_truth = importdata(config.GT_FP);
time_delta = config.TIME_DELTA;
max_overlap_unit = nan(size(blind_pass_table,1),1);
overlap_percentages = cell(size(blind_pass_table,1),1);
max_overlap_percentages = nan(size(blind_pass_table,1),1);
num_iterations = size(sliced_bp_table,1);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"add_overlap_percentage_col_and_max_overlap_unit_optimized.m")

parallel_constant_ts = parallel.pool.Constant(timestamps);
parallel_constant_gt = parallel.pool.Constant(ground_truth);

parfor i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    timestamp_of_cluster = current_data{1,"timestamps"}{1};
    [overlap_percentages{i},max_overlap_unit(i),max_overlap_percentages(i)] =get_overlap_between_units_and_cluster_2_ptr_method(timestamp_of_cluster,parallel_constant_gt.Value,parallel_constant_ts.Value,time_delta);
    send(q,[]);
end
blind_pass_table.("Max_Overlap_perc_With_Unit") = max_overlap_percentages;
blind_pass_table.("Max_Overlap_Unit") = max_overlap_unit;
blind_pass_table.("overlap_perc_with_all_units") = overlap_percentages;

end