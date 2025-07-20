function [accuracy_array] = calculate_accuracy(gt_ts,cell_array_of_all_cluster_ts,config)
accuracy_array = nan(1,size(cell_array_of_all_cluster_ts,2));
for i=1:size(cell_array_of_all_cluster_ts,2)
    cluster_ts = cell_array_of_all_cluster_ts{i};
    if size(gt_ts,2) < size(cluster_ts,1)
        tp = find_number_of_true_positives_given_a_time_delta_hpc(gt_ts,cluster_ts.',config.TIME_DELTA); % a spike that is in both the cluster and the unit with some time delta specified in seconds
    else
        tp = find_number_of_true_positives_given_a_time_delta_hpc(cluster_ts.',gt_ts,config.TIME_DELTA);
    end
    fn = length(gt_ts) - tp; % a spike in the unit, but not in the cluster
    tn = 0; % this would be a spike in the same configuration ie
    %                                   |z score n|tetrode i| cluster a
    %but not assigned to this cluster
    %we set this equal to 0 because it is not a helpful metric and costly to compute
    fp = length(cluster_ts) - tp; % aspike that is in the cluster, but does not have a correlative spike in the unit

    accuracy_array(i) = ((tp +tn)/(tp+fn+tn+fp));
    if accuracy_array(i) >100
        print("Something is wrong");
    end
end
end