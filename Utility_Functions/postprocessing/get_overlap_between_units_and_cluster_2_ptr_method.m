function [array_of_overlap_with_unit,unit_of_max_overlap,max_overlap_percentage] = get_overlap_between_units_and_cluster_2_ptr_method(timestamps_of_cluster,ground_truth,timestamps,time_delta)

%find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs()
array_of_overlap_with_unit = zeros(1,length(ground_truth));
max_overlap_percentage = 0;
unit_of_max_overlap = NaN;
% num_iterations = length(ground_truth);
% q = parallel.pool.DataQueue;
% afterEach(q,@print_status_bar)
% print_status_bar(num_iterations,"get_overlap_between_cluster_and_unit_as_percentage_ver_2.m")

for i=1:length(ground_truth)
    current_unit_ts_locs = ground_truth{i};
    number_of_times_current_unit_spikes = size(current_unit_ts_locs,2);
    %disp(current_unit_ts_locs)
    if all(mod(current_unit_ts_locs,1)==0) %current_unit_ts_locs is index format and thus we should index the timestamps
        current_unit_ts_locs = current_unit_ts_locs +1; %we do this because the ground truth output comes from a python library meaning it's 0-based
        %we add 1 to account
        %for this offset
        current_unit_ts = timestamps(current_unit_ts_locs);
    else %current_unit_ts_locs is already in ts so we don't need to index them (as is the case of paired datasets)
        current_unit_ts = current_unit_ts_locs;
    end
    
    [~,~,number_of_ts_in_common] = find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(timestamps_of_cluster,current_unit_ts,time_delta);
    percentage_of_units_spikes_in_cluster = (number_of_ts_in_common / number_of_times_current_unit_spikes) * 100;
    if percentage_of_units_spikes_in_cluster > max_overlap_percentage
        max_overlap_percentage = percentage_of_units_spikes_in_cluster;
        unit_of_max_overlap = i;
    end
    array_of_overlap_with_unit(i) = percentage_of_units_spikes_in_cluster;
    % send(q,[]);
end
end