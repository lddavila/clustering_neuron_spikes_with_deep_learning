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
number_per_classes = 25000;
indexes_to_use_for_training_left_is_better = randperm(length(indexes_where_neuron_is_same),number_per_classes);
indexes_to_use_for_training_right_is_better = randperm(length(indexes_where_neuron_is_not_same),number_per_classes);

indexes_to_use_for_training = [indexes_where_neuron_is_same(indexes_to_use_for_training_left_is_better).',indexes_where_neuron_is_not_same(indexes_to_use_for_training_right_is_better)];

%now shuffle
indexes_to_use_for_training = indexes_to_use_for_training(randperm(length(indexes_to_use_for_training)));


%now assemble the data
left_clust_data_training = cellfun(@(x) x(all_comparisons_for_training(indexes_to_use_for_training,1),:),all_assembled_data,'UniformOutput',false);
left_clust_data_training = cell2mat(left_clust_data_training);
right_clust_data_training= cellfun(@(x) x(all_comparisons_for_training(indexes_to_use_for_training,2),:),all_assembled_data,'UniformOutput',false);
right_clust_data_training = cell2mat(right_clust_data_training);

final_validation_data = [left_clust_data_training,right_clust_data_training];

%now check how they perform on this new set of data

scores = predict(net,final_validation_data(:,:));
[~,YPred] = max(scores,[],2);
YPred = YPred-1;

final_accuracy = sum(YPred== same_neuron(indexes_to_use_for_training))/numel(same_neuron(indexes_to_use_for_training));

fprintf("Final accuracy%.2f",final_accuracy)

end