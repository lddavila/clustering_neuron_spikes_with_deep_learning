function [blind_pass_table] = add_ks4_score(blind_pass_table,config)
beginning = tic;
ground_truth_array = importdata(config.GT_FP);
timestamps = importdata(config.TIMESTAMP_FP);
disp("Finished importing ground truth and timestamps");
time_delta = config.TIME_DELTA;
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,["Max Overlap Unit"]);

for i=1:size(sliced_bp_table,1)
   % If an estimated spike from a detected unit was less than or equal to
   % 0.2 ms from a ground-truth spike it was counted as a positive match.
   % The FP rate was defined as the number of estimated spikes without a
   % positive match divided by the total number of estimated spikes. The FN
   % rate was defined as the number of missed ground-truth spikes divided
   % by the total number of ground-truth spikes. We matched the
   % ground-truth unit with the detected unit that maximized the score,
   % defined as 1 − FP − FN (ref. 6). The upper bound of the score is 1. In
   % Fig. 4e–j, the ground-truth units were sorted by their score from each
   % algorithm separately. We defined ground-truth units as being correctly
   % identified in Fig. 4j if the score was higher than 0.8.

   current_data = sliced_bp_table{i};
   ground_truth_ts_idxs = ground_truth_array{i};
   gt_ts = timestamps(ground_truth_ts_idxs);
   ks4_score = zeros(size(current_data,1),1);
   sliced_current_data = slice_table_for_parallel_processing(current_data,[]);
   
   for j=1:size(current_data,1)
       current_cluster = sliced_current_data{j};
       estimated_spikes_without_positive_match = size(current_cluster{1,"timestamps"}{1},1);
       missed_gt_ts = length(gt_ts);
       current_cluster_ts =current_cluster{1,"timestamps"}{1} ;
       
       cluster_ts_pointer = 1;
       gt_ts_pointer = 1;
       while cluster_ts_pointer <= length(current_cluster_ts) && gt_ts_pointer <= length(gt_ts)
           difference_between_spike_ts = abs(gt_ts(gt_ts_pointer) -current_cluster_ts(cluster_ts_pointer));

           if difference_between_spike_ts <= time_delta
               %spikes are close enough to be considered the same
               cluster_ts_pointer = cluster_ts_pointer+1;
               gt_ts_pointer = gt_ts_pointer+1;
               estimated_spikes_without_positive_match = estimated_spikes_without_positive_match-1;
               missed_gt_ts = missed_gt_ts-1;
           elseif current_cluster_ts(cluster_ts_pointer) < gt_ts(gt_ts_pointer)-time_delta
               %the cluster timestamp is coming too early
               %cluster_ts(cluster_ts_pointer) + time_delta < gt_ts(gt_ts_pointer)
                cluster_ts_pointer = cluster_ts_pointer+1;
           elseif current_cluster_ts(cluster_ts_pointer) > gt_ts(gt_ts_pointer)+time_delta
               %the cluster timestamp is too late
               %so we have to update the gt timestamp we are looking at
               gt_ts_pointer = gt_ts_pointer+1;

           end
       end


       FP_rate = estimated_spikes_without_positive_match / size(current_cluster{1,"timestamps"}{1},1);
       FN_rate = missed_gt_ts / length(gt_ts);
       ks4_score(j) = 1 - FP_rate - FN_rate;

       if ks4_score(j) > 1
           disp("something went wrong")
       end
       
       
       % disp(string(i)+" " +string(j)+"/"+string(size(current_data,1)))

   end
   current_data.ks4_score = ks4_score;
   sliced_bp_table{i} = current_data;

end
blind_pass_table = vertcat(sliced_bp_table{:});
ending = toc(beginning);
disp("It took "+string(ending)+" seconds")
end