function [] = test_neural_net_on_never_before_seen_data(blind_pass_table,fp_to_nn,config)

% blind_pass_table = blind_pass_table(blind_pass_table{:,"accuracy"}>40,:);
net_struct = importdata(fp_to_nn);
net = net_struct.net;
normalizing_min = net_struct.normalizing_min;
normalizing_max = net_struct.normalizing_max;

%get pairs of blind pass comparisons
all_comparisons_for_training = nchoosek(1:size(blind_pass_table,1),2);

%now get all data from the blind pass table
list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","histogram 1","histogram 2", "histogram 3","histogram 4","size","grades 2"];
all_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);
disp("Finished data assembly")

%normalize the assembled data based on training norms found during training
for i=1:length(all_assembled_data)
    col_max = normalizing_max{i};
    col_min = normalizing_min{i};
    range = col_max - col_min;
    range(range==0) = eps;
    all_assembled_data{i} = (all_assembled_data{i} - col_min) ./ range;
end
disp("Finished data normalization")

%now check for all comparisons whether or not the item in the left col is better
is_left_better = blind_pass_table{all_comparisons_for_training(:,1),"accuracy"} >= blind_pass_table{all_comparisons_for_training(:,2),"accuracy"};
disp("Finished is left better")

%get indexes of classes where the left cluster is better
indexes_where_left_is_better = find(is_left_better);
indexes_where_right_is_better = setdiff(1:size(is_left_better,1),indexes_where_left_is_better);
disp("finished getting left/right indexes")

rng(0)
%now get the same number of samples from each class
number_per_classes = 25000;
indexes_to_use_for_training_left_is_better = randperm(length(indexes_where_left_is_better),number_per_classes);
indexes_to_use_for_training_right_is_better = randperm(length(indexes_where_right_is_better),number_per_classes);

indexes_to_use_for_training = [indexes_where_left_is_better(indexes_to_use_for_training_left_is_better).',indexes_where_right_is_better(indexes_to_use_for_training_right_is_better)];

%now shuffle
indexes_to_use_for_training = indexes_to_use_for_training(randperm(length(indexes_to_use_for_training)));


%now assemble the data
left_clust_data_training = cellfun(@(x) x(all_comparisons_for_training(indexes_to_use_for_training,1),:),all_assembled_data,'UniformOutput',false);
left_clust_data_training = cell2mat(left_clust_data_training);
right_clust_data_training= cellfun(@(x) x(all_comparisons_for_training(indexes_to_use_for_training,2),:),all_assembled_data,'UniformOutput',false);
right_clust_data_training = cell2mat(right_clust_data_training);

final_validation_data = left_clust_data_training -right_clust_data_training;

%now check how they perform on this new set of data

scores = predict(net,final_validation_data(:,:));
[~,YPred] = max(scores,[],2);
YPred = YPred-1;

final_accuracy = sum(YPred== is_left_better(indexes_to_use_for_training))/numel(is_left_better(indexes_to_use_for_training));

fprintf("Final accuracy%.2f",final_accuracy)

end