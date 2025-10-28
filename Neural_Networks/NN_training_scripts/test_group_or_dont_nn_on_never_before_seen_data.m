function [] = test_group_or_dont_nn_on_never_before_seen_data(blind_pass_table,fp_to_nn,config)

%set seed for reproducability
rng(0)

% blind_pass_table = blind_pass_table(blind_pass_table{:,"accuracy"}>40,:);
net = importdata(fp_to_nn);

%the group_or_dont neural network only provides 2 outputs
%0 (don't group)
%1 (do group)
% we want to ensure that we equally sample each classes in the data set to
% ensure that we're not performing undue bias
number_of_samples_per_class = 2000;


% let's get all possible comparisons in the blind pass data
all_comparisons = nchoosek(1:size(blind_pass_table,1),2);

%get the true class of each comparison
group_or_dont_true_class = blind_pass_table{all_comparisons(:,1),"Max_Overlap_Unit"} == blind_pass_table{all_comparisons(:,2),"Max_Overlap_Unit"};


%now split the groupable and non groupable comparisons
is_groupable_comparisons = all_comparisons(group_or_dont_true_class==1,:);

is_not_groupable_comparisons = all_comparisons(group_or_dont_true_class==0,:);

%now randomly sample those comparisons
random_is_groupable_comparisons = is_groupable_comparisons(randperm(size(is_groupable_comparisons,1),number_of_samples_per_class),:);
random_isnt_groupable_comparisons = is_not_groupable_comparisons(randperm(size(is_not_groupable_comparisons,1),number_of_samples_per_class),:);

%now combine these groups into a single variable
rows_for_training = [random_is_groupable_comparisons;random_isnt_groupable_comparisons];
true_class = [ones(size(random_is_groupable_comparisons,1),1);zeros(size(random_isnt_groupable_comparisons,1),1)];
%for each row in rows_for_training calculate the overlap
overlap_array = zeros(size(rows_for_training,1),1);
rows_for_training_parallel = parallel.pool.Constant(rows_for_training);
blind_pass_table_parallel = parallel.pool.Constant(blind_pass_table);
config_parallel = parallel.pool.Constant(config);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(rows_for_training_parallel.Value,1);
print_status_bar(num_iterations,"getting overlap for testing group_or_dont");
if ~isfile("overlap_col.mat")
    for j=1:size(rows_for_training_parallel.Value,1)
        cluster_1_idx = rows_for_training_parallel.Value(j,1);
        cluster_2_idx = rows_for_training_parallel.Value(j,2);

        cluster_1_ts = blind_pass_table_parallel.Value{cluster_1_idx,"timestamps"}{1};
        cluster_2_ts = blind_pass_table_parallel.Value{cluster_2_idx,"timestamps"}{1};

        [overlap_array(j),~,~] =find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
        send(q,[]);
    end
    par_save("overlap_col.mat",overlap_array);
else
    overlap_array = importdata("overlap_col.mat");
end


%now we can assemble the data required for the group_or_dont neural network
list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","histogram 1","histogram 2", "histogram 3","histogram 4","size"];
assembled_data = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);

left_clust_data = cellfun(@(x) x(rows_for_training(:,1),:),assembled_data,'UniformOutput',false);
left_clust_data = cell2mat(left_clust_data);
right_clust_data = cellfun(@(x) x(rows_for_training(:,2),:),assembled_data,'UniformOutput',false);
right_clust_data = cell2mat(right_clust_data);

final_validation_data = [left_clust_data,right_clust_data,overlap_array];


%now check how they perform on this new set of data

scores = predict(net,final_validation_data(:,:));
[~,YPred] = max(scores,[],2);
YPred = YPred-1;

final_accuracy = sum(YPred== true_class)/numel(true_class);

fprintf("Final accuracy%.2f\n",final_accuracy)

end