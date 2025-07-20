function [overlap_percentage] = get_overlap_percentage_between_2_cluster_ts(current_neuron_ts,current_compare_neuron_ts,config)

[~,index_of_larger ]= max([length(current_compare_neuron_ts),length(current_neuron_ts)]);
[smaller_cluster_size,~ ]= min([length(current_compare_neuron_ts),length(current_neuron_ts)]);
if index_of_larger==1
    %if the larger cluster is the compare neuron then we use the ts
    %of the current neuron as our compare
    number_of_timestamps_in_common = find_number_of_true_positives_given_a_time_delta_hpc(current_neuron_ts,current_compare_neuron_ts,config.TIME_DELTA);
elseif index_of_larger==2
    %if the larger cluster is the current_neuron then we use the ts
    %of the compare neuron as our compare
    %the logic behind this is that the first set of ts that are put
    %into the function will never be over counted
    number_of_timestamps_in_common = find_number_of_true_positives_given_a_time_delta_hpc(current_compare_neuron_ts,current_neuron_ts,config.TIME_DELTA);
else
    number_of_timestamps_in_common=0;
end

overlap_percentage = (number_of_timestamps_in_common / smaller_cluster_size) * 100;
end