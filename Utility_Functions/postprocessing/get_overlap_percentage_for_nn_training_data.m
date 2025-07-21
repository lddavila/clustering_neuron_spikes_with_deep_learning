function [array_of_overlap_percentages] = get_overlap_percentage_for_nn_training_data(blind_pass_table,idxs_of_sample_data,config)

lower_triangular_indexes =idxs_of_sample_data;


%slice the table of neurons in a way that the 2 being compared are in a single location of the cell array
sliced_table = cell(size(lower_triangular_indexes,1),1);
for i=1:size(lower_triangular_indexes,1)
    current_row_and_col = lower_triangular_indexes(i,:);
    current_row = current_row_and_col(1);
    current_col = current_row_and_col(2);
    sliced_table{i} = [blind_pass_table(current_row,"timestamps");blind_pass_table(current_col,"timestamps")];
    if mod(i,1000)==0
        print_status_iter_message("get_overlap_percentage_for_nn_training_data.m: slicing table",i,size(lower_triangular_indexes,1));
    end
end

num_iters = size(lower_triangular_indexes,1);
array_of_overlap_percentages = [];
parfor i=1:size(lower_triangular_indexes,1)
    current_data = sliced_table{i};
    current_neuron_ts = current_data{1,"timestamps"}{1};
    current_compare_neuron_ts = current_data{2,"timestamps"}{1};

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
    array_of_overlap_percentages = [array_of_overlap_percentages;(number_of_timestamps_in_common / smaller_cluster_size) * 100];
    if mod(i,1000) == 0
        print_status_iter_message("get_overlap_percentage_for_nn_training_data.m",i,num_iters)
    end
end




end