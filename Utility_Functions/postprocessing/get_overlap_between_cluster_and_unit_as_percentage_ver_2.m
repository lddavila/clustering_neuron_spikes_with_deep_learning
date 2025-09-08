function [array_of_overlap_with_unit,unit_of_max_overlap,max_overlap_percentage] = get_overlap_between_cluster_and_unit_as_percentage_ver_2(timestamps_of_cluster,ground_truth,timestamps,time_delta)

array_of_overlap_with_unit = zeros(1,length(ground_truth));
max_overlap_percentage = 0;
unit_of_max_overlap = NaN;
num_iterations = length(ground_truth);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"get_overlap_between_cluster_and_unit_as_percentage_ver_2.m")
for i=1:length(ground_truth)
    current_unit_ts_locs = ground_truth{i};
    number_of_times_current_unit_spikes = size(current_unit_ts_locs,2);
    current_unit_ts = timestamps(current_unit_ts_locs);
    
    %ORIGINAL BEGINS BELOW
    % number_of_ts_in_common = 0;
    % for j=1:number_of_times_current_unit_spikes
    %     diffs_between_unit_ts_and_cluster_ts = current_unit_ts(j) - timestamps_of_cluster;
    %     if any(abs(diffs_between_unit_ts_and_cluster_ts) < time_delta)
    %         number_of_ts_in_common = number_of_ts_in_common +1;
    %     end
    % 
    % end
    %ORIGINAL ENDS
    number_of_ts_in_common = ismembertol(current_unit_ts, timestamps_of_cluster, time_delta, 'DataScale', 1);
    percentage_of_units_spikes_in_cluster = (number_of_ts_in_common / number_of_times_current_unit_spikes) * 100;
    if percentage_of_units_spikes_in_cluster > max_overlap_percentage
        max_overlap_percentage = percentage_of_units_spikes_in_cluster;
        unit_of_max_overlap = i;
    end
    array_of_overlap_with_unit(i) = percentage_of_units_spikes_in_cluster;
    send(q,[]);
end
end