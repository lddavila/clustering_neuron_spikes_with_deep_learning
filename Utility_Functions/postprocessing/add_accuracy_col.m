function [table_of_clusters] = add_accuracy_col(config,table_of_clusters)
accuracy_array = nan(size(table_of_clusters,1),1);
ground_truth = importdata(config.GT_FP);
timestamps = importdata(config.TIMESTAMP_FP);
% accuracy_category = nan(size(table_of_clusters,1),1);
sliced_bp_table = slice_table_for_parallel_processing(table_of_clusters,[]);
num_iterations = size(table_of_clusters,1);
for i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    unit_that_cluster_has_max_overlap_with = current_data{1,"Max Overlap Unit"};
    gt_indexes =ground_truth{unit_that_cluster_has_max_overlap_with} ;
    gt_ts = timestamps(gt_indexes);
    cluster_spike_ts = current_data{1,"timestamps"}{1};
    display(gt_ts);
    display(cluster_spike_ts);
    accuracy_array(i) = calculate_accuracy(gt_ts,{cluster_spike_ts},config) * 100;
    disp("add_accuracy_col Finished "+string(i)+"/"+string(num_iterations));
end
table_of_clusters.accuracy = accuracy_array;
% table_of_clusters.accuracy_category = accuracy_category;
end