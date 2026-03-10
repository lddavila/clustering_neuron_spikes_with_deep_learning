function [overlap,matches_log,matches] = find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,time_delta)

switched = false;
%step 1 is to ensure that the ts are sorted
cluster_1_ts = sort(cluster_1_ts);
cluster_2_ts = sort(cluster_2_ts);

%ensure that the shorter of the 2 spike trains is ALWAYS stored in cluster_1_ts
if length(cluster_1_ts) > length(cluster_2_ts)
    temp = cluster_1_ts;
    cluster_1_ts = cluster_2_ts;
    cluster_2_ts = temp;
    switched= true;
end

%now establish 2 pointers to be used when finding overlap betwene the
%cluster spike trains
spike_train_1_pointer = 1;
spike_train_2_pointer = 1;

%now store the lenght of the larger and shorter spike trains
spike_train_1_length = length(cluster_1_ts);
spike_train_2_length = length(cluster_2_ts);

%we keep track of the matches in order to get a measurement of how much of
%the smaller cluster exists within the larger cluster
matches = 0;

%we also want to keep track of which ts are within the error tolerance in
%order to check up on them
matches_log = nan(min([spike_train_1_length,spike_train_2_length]),2); % preallocating for speed, will likely not need all of the preallocated rows in practice 
matches_log_counter = 1;
while spike_train_1_pointer <= spike_train_1_length && spike_train_2_pointer <= spike_train_2_length
    if abs(cluster_1_ts(spike_train_1_pointer)- cluster_2_ts(spike_train_2_pointer)) <= time_delta
        matches = matches +1;
        matches_log(matches_log_counter,:) = [spike_train_1_pointer,spike_train_2_pointer];
        matches_log_counter = matches_log_counter+1;
        spike_train_1_pointer = spike_train_1_pointer+1;
        spike_train_2_pointer = spike_train_2_pointer+1;
    elseif cluster_1_ts(spike_train_1_pointer) < cluster_2_ts(spike_train_2_pointer) %cluster_1's current spike is too early to ever match with cluster_2's current spike so we must advance it
        spike_train_1_pointer = spike_train_1_pointer+1;
    else %cluster_2's current spike is to early to ever match with cluster 1's current spike so we advance the pointer
        spike_train_2_pointer = spike_train_2_pointer+1;
    end

end
if matches < size(matches_log,1)
    matches_log(matches+1:end, :) = [];  % trim unused rows
end
overlap = matches /min([spike_train_1_length,spike_train_2_length]);
if switched
    matches_log = matches_log(:,[2,1]);
end
end