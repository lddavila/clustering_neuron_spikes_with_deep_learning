function [number_of_true_positives] = find_number_of_true_positives_given_a_time_delta_hpc(gt_data,ts_of_cluster,time_delta)
% tic
number_of_true_positives = 0;

% 
% gt_data =gpuArray(gt_data);
% ts_of_cluster = gpuArray(ts_of_cluster);
% already_counted = zeros(1,size(gt_data,2));
for i=1:length(gt_data)
    current_gt_spike_ts = gt_data(i);
    diffs_between_gt_ts_and_clust_ts = abs(current_gt_spike_ts - ts_of_cluster);

    % [smallest_difference,~] = min(abs(diffs_between_gt_ts_and_clust_ts));
    if any(diffs_between_gt_ts_and_clust_ts< time_delta)
        number_of_true_positives = number_of_true_positives+1;
    end
end

% vectorized check (faster implementation)
% mat_rep_of_cluster = repelem(ts_of_cluster,length(gt_data),1);
% abs_diffs = abs(gt_data.' - ts_of_cluster);
% mat_of_within_time_delta = abs_diffs < time_delta;
% number_of_true_positives = sum(any(mat_of_within_time_delta,1));

% toc
end