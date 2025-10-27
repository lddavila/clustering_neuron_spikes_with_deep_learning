function [] = test_group_or_dont_nn_on_never_before_seen_data(blind_pass_table,fp_to_nn,config)

% blind_pass_table = blind_pass_table(blind_pass_table{:,"accuracy"}>40,:);
net = importdata(fp_to_nn);

%get pairs of blind pass comparisons
all_comparisons_for_training = nchoosek(1:size(blind_pass_table,1),2);

%now get all data from the blind pass table
list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","histogram 1","histogram 2", "histogram 3","histogram 4","size"];
all_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);
disp("Finished data assembly")



%now check for all comparisons whether or not the item in the left col is better
same_neuron = blind_pass_table{all_comparisons_for_training(:,1),"Max_Overlap_Unit"}== blind_pass_table{all_comparisons_for_training(:,2),"Max_Overlap_Unit"};
disp("Finished getting is same neuron")

%get indexes of classes where the left cluster is better
indexes_where_neuron_is_same = find(same_neuron);
indexes_where_neuron_is_not_same = setdiff(1:size(same_neuron,1),indexes_where_neuron_is_same);
disp("finished getting left/right indexes")

rng(0)
%now get the same number of samples from each class
number_per_classes = 10000;
indexes_to_use_for_training_neuron_is_the_same = randperm(length(indexes_where_neuron_is_same),number_per_classes);
indexes_to_use_for_training_neuron_isnt_same = randperm(length(indexes_where_neuron_is_not_same),number_per_classes);

indexes_to_use_for_training = [indexes_where_neuron_is_same(indexes_to_use_for_training_neuron_is_the_same).',indexes_where_neuron_is_not_same(indexes_to_use_for_training_neuron_isnt_same)];

%now shuffle
%indexes_to_use_for_training = indexes_to_use_for_training(randperm(length(indexes_to_use_for_training)));


%get the overlap between the 2 comparisons
overlap_array = zeros(length(indexes_to_use_for_training),1);
blind_pass_table_parallel = parallel.pool.Constant(blind_pass_table);
all_comparisons_for_training_parallel = parallel.pool.Constant(all_comparisons_for_training(indexes_to_use_for_training,:));
config_parallel = parallel.pool.Constant(config);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(indexes_to_use_for_training,2);
print_status_bar(num_iterations,"getting overlap for testing:");
if ~isfile("overlap_col.mat")
    for j=1:size(indexes_to_use_for_training,2)

        cluster_1_ts = blind_pass_table_parallel.Value{all_comparisons_for_training_parallel.Value(j,1),"timestamps"}{1};
        cluster_2_ts = blind_pass_table_parallel.Value{all_comparisons_for_training_parallel.Value(j,2),"timestamps"}{1};
        [overlap_array(j),~,~] =find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
        send(q,[]);
    end
    par_save("overlap_col.mat",overlap_array);
else
    overlap_array = importdata("overlap_col.mat");
    %overlap_array = [overlap_array;overlap_array];
end


%now assemble the data
left_clust_data_training = cellfun(@(x) x(all_comparisons_for_training(indexes_to_use_for_training,1),:),all_assembled_data,'UniformOutput',false);
left_clust_data_training = cell2mat(left_clust_data_training);
right_clust_data_training= cellfun(@(x) x(all_comparisons_for_training(indexes_to_use_for_training,2),:),all_assembled_data,'UniformOutput',false);
right_clust_data_training = cell2mat(right_clust_data_training);

final_validation_data = [left_clust_data_training,right_clust_data_training,overlap_array];

%now check how they perform on this new set of data

scores = predict(net,final_validation_data(:,:));
[~,YPred] = max(scores,[],2);
YPred = YPred-1;

final_accuracy = sum(YPred== same_neuron(indexes_to_use_for_training))/numel(same_neuron(indexes_to_use_for_training));

fprintf("Final accuracy%.2f",final_accuracy)

end