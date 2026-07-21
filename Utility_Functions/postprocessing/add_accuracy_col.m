function [table_of_clusters,raw_tp_count] = add_accuracy_col(config,table_of_clusters,varargin)
accuracy_array = nan(size(table_of_clusters,1),1);
ground_truth = importdata(config.GT_FP);
if string(class(ground_truth)) ~= "cell"
    ground_truth_temp = ground_truth;
    ground_truth = cell(1,1);
    ground_truth{1} = ground_truth_temp;
end
timestamps = importdata(config.TIMESTAMP_FP);
% accuracy_category = nan(size(table_of_clusters,1),1);
sliced_bp_table = slice_table_for_parallel_processing(table_of_clusters,[]);
if isempty(varargin)
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = length(sliced_bp_table);
    print_status_bar(num_iterations,"add_accuracy_col.m")
end
timestamps = parallel.pool.Constant(timestamps);
ground_truth = parallel.pool.Constant(ground_truth);
raw_tp_count = nan(size(table_of_clusters,1),1);
raw_fn_count = nan(size(table_of_clusters,1),1);
raw_fp_count = nan(size(table_of_clusters,1),1);
for i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    %blind_pass_table.("Max_Overlap_perc_With_Unit") = max_overlap_percentages;
    %blind_pass_table.("Max_Overlap_Unit") = max_overlap_unit;
    %blind_pass_table.("overlap_perc_with_all_units") = overlap_percentages;


    unit_that_cluster_has_max_overlap_with = current_data{1,"Max_Overlap_Unit"};
    if isnan(unit_that_cluster_has_max_overlap_with)
        accuracy_array(i) = 0;
        if isempty(varargin)
            send(q,[])
        end
        continue;
    end
    gt_indexes =ground_truth.Value{unit_that_cluster_has_max_overlap_with} ;

    %paired recordings data is saved already in timestamps so we don't need
    %to index timestamps like we do in simulated data
    if all(mod(gt_indexes,1)==0)
        %the gt_indexes are 0 based (because they come from python)
        %so we'll add 1 to all the gt_indexes to make them line up
        gt_indexes = gt_indexes+1;
        gt_ts = timestamps.Value(gt_indexes);

    else
        gt_ts = gt_indexes;
    end

    cluster_spike_ts = current_data{1,"timestamps"}{1};

    [accuracy_array(i),raw_tp_count(i),raw_fn_count(i),raw_fp_count(i)] = calculate_accuracy(gt_ts,{cluster_spike_ts},config);
    accuracy_array(i) = accuracy_array(i) * 100;
    if isempty(varargin)
        send(q,[]);
    end

end
table_of_clusters.accuracy = accuracy_array;
table_of_clusters.tp = raw_tp_count;
table_of_clusters.fn = raw_fn_count;
table_of_clusters.fp = raw_fp_count;
% table_of_clusters.accuracy_category = accuracy_category;
end