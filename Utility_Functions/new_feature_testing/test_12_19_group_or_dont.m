function [] = test_12_19_group_or_dont(blind_pass_table,fp_to_nn,config)

%set seed for reproducability
rng(0)

%get the x,y locations of the channels on the probe
locations = get_probe_xy();

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

overlap_array = overlap_array * 100;

%get the assembled data for the true class
list_of_features_to_add = ["mean_waveform_rep_wire_1","rep_wire"];
test_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);


%get the euclidean distances between the left/right cluster waveforms
left_clust_wfs = test_assembled_data{1}(rows_for_training(:,1));
right_clust_wfs = test_assembled_data{1}(rows_for_training(:,2));
test_euc_distance_between_rep_wfs = vecnorm(left_clust_wfs - right_clust_wfs, 2, 2);



%test_data = [test_overlap,test_euc_distance_between_rep_wires,test_euc_distance_between_rep_wfs];

rep_wire_for_left_clust_test_data = test_assembled_data{2}(rows_for_training(:,1));
rep_wire_for_left_clust_test_data_loc = locations(rep_wire_for_left_clust_test_data,:);
rep_wire_for_right_clust_test_data = test_assembled_data{2}(rows_for_training(:,2));
rep_wire_for_right_clust_test_data_loc = locations(rep_wire_for_right_clust_test_data,:);
test_euc_distance_between_rep_wires = vecnorm(rep_wire_for_left_clust_test_data_loc - rep_wire_for_right_clust_test_data_loc,2, 2);

%now assemble the test data
%training_data = [training_overlap,training_euc_distance_between_rep_wires,training_euc_distance_between_rep_wfs,training_left_col_size,training_right_col_size];
test_data = [overlap_array,test_euc_distance_between_rep_wires,test_euc_distance_between_rep_wfs];

%append the true class to the end of the test data
test_data = [test_data,true_class];

%shuffle the test data
test_data = test_data(randperm(size(test_data,1),size(test_data,1)),:);

%now test the trained neural network on never before seen comparisons
scores = predict(net,test_data(:,1:end-1));
[~,YPred] = max(scores,[],2);
YPred = YPred-1;

accuracy = sum(YPred==test_data(:,end))/size(test_data,1);

%print out a statement to reflect accuracy
fprintf("Accuracy on test data: %.2f",accuracy*100);
end