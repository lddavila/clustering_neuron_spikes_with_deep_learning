function [table_of_clusters] = add_accuracy_col(config,table_of_clusters)
accuracy_array = nan(size(table_of_clusters,1),1);
ground_truth = importdata(config.GT_FP);
timestamps = importdata(config.TIMESTAMP_FP);
% accuracy_category = nan(size(table_of_clusters,1),1);
sliced_bp_table = slice_table_for_parallel_processing(table_of_clusters,[]);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(sliced_bp_table);
print_status_bar(num_iterations,"add_accuracy_col.m")
timestamps = parallel.pool.Constant(timestamps);
ground_truth = parallel.pool.Constant(ground_truth);
parfor i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    %blind_pass_table.("Max_Overlap_perc_With_Unit") = max_overlap_percentages;
%blind_pass_table.("Max_Overlap_Unit") = max_overlap_unit;
%blind_pass_table.("overlap_perc_with_all_units") = overlap_percentages;


    unit_that_cluster_has_max_overlap_with = current_data{1,"Max_Overlap_Unit"};
    gt_indexes =ground_truth.Value{unit_that_cluster_has_max_overlap_with} ;
    %the gt_indexes are 0 based (because they come from python)
    %so we'll add 1 to all the gt_indexes to make them line up
    gt_indexes = gt_indexes+1;
    gt_ts = timestamps.Value(gt_indexes);
    cluster_spike_ts = current_data{1,"timestamps"}{1};

    accuracy_array(i) = calculate_accuracy(gt_ts,{cluster_spike_ts},config) * 100;
    send(q,[]);
   
end
table_of_clusters.accuracy = accuracy_array;
% table_of_clusters.accuracy_category = accuracy_category;
end