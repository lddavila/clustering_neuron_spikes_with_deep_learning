function [blind_pass_table] = add_overlap_percentage_col_and_max_overlap_unit(blind_pass_table,config)
% spikesort_config
timestamps = importdata(config.TIMESTAMP_FP);
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
ground_truth = importdata(config.GT_FP);
time_delta = config.TIME_DELTA;
max_overlap_unit = nan(size(blind_pass_table,1),1);
overlap_percentages = cell(size(blind_pass_table,1),1);
max_overlap_percentages = nan(size(blind_pass_table,1),1);
parfor i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    timestamp_of_cluster = current_data{1,"timestamps"}{1};
    [overlap_percentages{i},max_overlap_unit(i),max_overlap_percentages(i)] =get_overlap_between_cluster_and_unit_as_percentage_ver_2(timestamp_of_cluster,ground_truth,timestamps,time_delta);

end
blind_pass_table.("Max Overlap % With Unit") = max_overlap_percentages;
blind_pass_table.("Max Overlap Unit") = max_overlap_unit;
blind_pass_table.("overlap % with all units") = overlap_percentages;

end