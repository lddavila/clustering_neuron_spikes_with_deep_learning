function [] = train_most_simplified_group_or_dont_nn_without_size(varargin)
%the simplest group or dont neural network model 
%only takes overlap, the euc distance between the mean wfs, and the euc
%distance between the rep wires of each cluster

current_script_file_path = mfilename('fullpath');
[current_script_dir,~,~] = fileparts(current_script_file_path);
cd(current_script_dir);

%first let's put all files on the path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
disp("Finished setting path")

%now we must get the config
config = spikesort_config();
parent_save_dir = config.parent_save_dir;
disp("Finished Loading Config")

%get the x,y locations of the channels on the probe
locations = get_probe_xy();

%for AF's account broken profile
if contains(config.base_file_path,"afriedman")
    parpool('local_40', 40);
end

%create a directory where the results will be saved
dir_to_save_results_to = fullfile(parent_save_dir,"simplest_group_or_dont_no_size");
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating directory")


%now we load the master training blind pass table which has various
%examples with various noise levels and accuracy
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_MASTER_TRAINING_BP_TABLE);
else
    blind_pass_table = varargin{1};
end
%blind_pass_table.og_index = (1:size(blind_pass_table,1)).';
disp("Finished loading blind pass table")


%set the random seed for repeatable results
rng("default")
disp("Finished setting seed")

%remove any data that has accuracy less than 10
blind_pass_table = blind_pass_table(blind_pass_table{:,"accuracy"}>10,:);

%partition the blind pass table into test training data
paritioned_bp_table_array = partition_bp_tables(blind_pass_table,0);
training_data = paritioned_bp_table_array{1,1};
test_data = paritioned_bp_table_array{1,2};


%partition the training data into training and validation data
paritioned_training_data = partition_bp_tables(training_data,0);
training_data = paritioned_training_data{1,1};
val_data = paritioned_training_data{1,2};




%now navigate into the dir where we will save the results to
cd(dir_to_save_results_to);

%there's a practically infinit number of comarisons that can be made so we
%have to specify how many we'll realistically generate for training as
%computing the overlap feature can be very expensive
%0 = not groupable AKA do not represent the same underlying neuron
%1 = is groupable AKAK does represent the same underlying neuron
number_of_comparisons_per_class = 10000;

%get all possible comparisons of the training_set
all_training_comparisons = nchoosek(1:size(training_data,1),2);

%get all possible comparisons of the validation set
all_valdiation_comparisons = nchoosek(1:size(val_data,1),2);

%get the true class for all training comparisons 
training_true_class = training_data{all_training_comparisons(:,1),"Max_Overlap_Unit"}==training_data{all_training_comparisons(:,2),"Max_Overlap_Unit"};

%get the true class for all validation comparisons
validation_true_class = val_data{all_valdiation_comparisons(:,1),"Max_Overlap_Unit"} ==val_data{all_valdiation_comparisons(:,2),"Max_Overlap_Unit"};

%randomly select number_of_comparisons_per_class from all comparisons in
%the training data
training_comparisons_with_class_1 = find(training_true_class);
training_is_same_idxs = training_comparisons_with_class_1(randperm(length(training_comparisons_with_class_1),number_of_comparisons_per_class));

training_comparisons_with_class_0 = find(~training_true_class);
training_is_not_same_idxs = training_comparisons_with_class_0(randperm(length(training_comparisons_with_class_0),number_of_comparisons_per_class *2));

%combine these idxs into single array
all_training_idxs = [training_is_not_same_idxs;training_is_same_idxs];

%randomly select number_of_comparisons_per_class from all comparisons in
%the validation data
val_comparisons_with_class_1 = find(validation_true_class);
val_is_same_idxs = val_comparisons_with_class_1(randperm(length(val_comparisons_with_class_1),number_of_comparisons_per_class));

val_comparisons_with_class_0 = find(~validation_true_class);
val_is_not_same_idxs = val_comparisons_with_class_0(randperm(length(val_comparisons_with_class_0),number_of_comparisons_per_class *2));

%combine all these idxs into single array
all_val_idxs = [val_is_not_same_idxs;val_is_same_idxs];

% now that we have the required idxs for both the training and validation
% data we can actually get the data that is required for training

%extract some required data for the computations we need to do
list_of_features_to_add = ["mean_waveform_rep_wire_1","size","rep_wire"];
training_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,training_data,config);
val_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,val_data,config);

%now get the overlap for all training data comparisons
training_overlap = nan(length(all_training_idxs),1);
for i=1:size(training_overlap,1)
    cluster_1_ts = training_data{all_training_comparisons(all_training_idxs(i),1),"timestamps"}{1};
    cluster_2_ts = training_data{all_training_comparisons(all_training_idxs(i),2),"timestamps"}{1};
    [training_overlap(i),~,~]=find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config.TIME_DELTA);
end

%now get the overlap for all the validation data
validation_overlap = nan(length(all_val_idxs),1);
for i=1:length(validation_overlap)
    cluster_1_ts = val_data{all_valdiation_comparisons(all_val_idxs(i),1),"timestamps"}{1};
    cluster_2_ts = val_data{all_valdiation_comparisons(all_val_idxs(i),2),"timestamps"}{1};
    [validation_overlap(i),~,~] = find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config.TIME_DELTA);
end

%now get the euclidean distance between the training data rep wire
%comparisons
rep_wire_for_left_clust_training_data = training_assembled_data{3}(all_training_comparisons(all_training_idxs,1));
rep_wire_for_left_clust_training_data_loc = locations(rep_wire_for_left_clust_training_data,:);
rep_wire_for_right_clust_training_data = training_assembled_data{3}(all_training_comparisons(all_training_idxs,2));
rep_wire_for_right_clust_training_data_loc = locations(rep_wire_for_right_clust_training_data,:);
training_euc_distance_between_rep_wires = vecnorm(rep_wire_for_left_clust_training_data_loc - rep_wire_for_right_clust_training_data_loc, 2, 2);

%now get the euclidean distance between the validataion data rep wire
%comparisons
rep_wire_for_left_clust_val_data = val_assembled_data{3}(all_valdiation_comparisons(all_val_idxs,1));
rep_wire_for_left_clust_val_data_loc = locations(rep_wire_for_left_clust_val_data,:);
rep_wire_for_right_clust_val_data = val_assembled_data{3}(all_valdiation_comparisons(all_val_idxs,2));
rep_wire_for_right_clust_val_data_loc = locations(rep_wire_for_right_clust_val_data,:);
val_euc_distance_between_rep_wires = vecnorm(rep_wire_for_left_clust_val_data_loc - rep_wire_for_right_clust_val_data_loc,2, 2);

%get the euclidean distance between the training data mean rep waveform
%comparisons
rep_wf_for_left_clust_training_data = training_assembled_data{1}(all_training_comparisons(all_training_idxs,1));
rep_wf_for_right_clust_training_data = training_assembled_data{1}(all_training_comparisons(all_training_idxs,2));
training_euc_distance_between_rep_wfs = vecnorm(rep_wf_for_left_clust_training_data - rep_wf_for_right_clust_training_data, 2, 2);

%get the euclidean distance between the validation data mean rep waveforms
%comparisons
rep_wf_for_left_clust_val_data = val_assembled_data{1}(all_valdiation_comparisons(all_val_idxs,1));
rep_wf_for_right_clust_val_data = val_assembled_data{1}(all_valdiation_comparisons(all_val_idxs,2));
val_euc_distance_between_rep_wfs = vecnorm(rep_wf_for_left_clust_val_data - rep_wf_for_right_clust_val_data, 2, 2);

%get the size of of all left and right clusters for the training comparisons
% training_left_col_size = training_assembled_data{2}(all_training_comparisons(all_training_idxs,1));
% training_right_col_size = training_assembled_data{2}(all_training_comparisons(all_training_idxs,2));

%get the size of all the left and right clusters for the validations
%comparisons
% validation_left_col_size = val_assembled_data{2}(all_valdiation_comparisons(all_val_idxs,1));
% validation_right_col_size = val_assembled_data{2}(all_valdiation_comparisons(all_val_idxs,2));
%now we can finally assemble the validation and training data
training_data = [training_overlap,training_euc_distance_between_rep_wires,training_euc_distance_between_rep_wfs];
validation_data = [validation_overlap,val_euc_distance_between_rep_wires,val_euc_distance_between_rep_wfs];



%now we'll define a single neural network architecture which we'll hope can
%generalize
%10=num neurons per layer
%5 = num layers
%2 = number of classes
%4 = number of features in assembled data
layers_of_net = dynamically_create_layers_for_nn(size(training_data,2),10,5,2);

%now add the true classes to the training and validation data
training_data = [training_data,training_true_class(all_training_idxs)];
validation_data = [validation_data,validation_true_class(all_val_idxs)];

%now we shuffle the rows of training and validation data
training_data = training_data(randperm(size(training_data,1),size(training_data,1)),:);
validation_data = validation_data(randperm(size(validation_data,1),size(validation_data,1)),:);

%now we can begin training
if ~isfile("simplest_group_or_dont.mat")
    [accuracy,net] = test_nn_on_incremental_challenging(training_data,validation_data,layers_of_net,64);
    fprintf("Accuracy on training and validation data: %.2f",accuracy*100);

    par_save("simplest_group_or_dont.mat",net);
else
    net = importdata("simplest_group_or_dont.mat");
end
%now we'll check how this data will work on never before seen comparisons
%that come from the testing data that we partitoned at the beginning
all_test_comparisons = nchoosek(1:size(test_data,1),2);

%get the true class for the test data comparisons
test_true_class = test_data{all_test_comparisons(:,1),"Max_Overlap_Unit"} ==test_data{all_test_comparisons(:,2),"Max_Overlap_Unit"} ;


%select number_of_comparisons_per_class
test_comparisons_with_class_1 = find(test_true_class);
test_comparisons_with_class_0 = find(~test_true_class);

test_class_1_idxs = randperm(length(test_comparisons_with_class_1),number_of_comparisons_per_class);
test_class_0_idxs = randperm(length(test_comparisons_with_class_0),number_of_comparisons_per_class);

%combine these idxs into a single array
all_test_idxs = [test_class_0_idxs,test_class_1_idxs];

%get the assembled data for the true class
list_of_features_to_add = ["mean_waveform_rep_wire_1","size","rep_wire"];
test_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,test_data,config);

%get the size of the left and right clusters
% test_left_clust_size = test_assembled_data{2}(all_test_comparisons(all_test_idxs,1));
% test_right_clust_size = test_assembled_data{2}(all_test_comparisons(all_test_idxs,2));

%get the euclidean distances between the left/right cluster waveforms
left_clust_wfs = test_assembled_data{1}(all_test_comparisons(all_test_idxs,1));
right_clust_wfs = test_assembled_data{1}(all_test_comparisons(all_test_idxs,2));
test_euc_distance_between_rep_wfs = vecnorm(left_clust_wfs - right_clust_wfs, 2, 2);

%get the overlap feature for all the test comparisons
test_overlap = nan(length(all_test_idxs),1);
for i=1:length(test_overlap)
    cluster_1_ts = test_data{all_test_comparisons(all_test_idxs(i),1),"timestamps"}{1};
    cluster_2_ts = test_data{all_test_comparisons(all_test_idxs(i),2),"timestamps"}{1};
    [test_overlap(i),~,~]=find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config.TIME_DELTA);
end

%now get the euclidean distance from the rep wires of all the test comparisons
rep_wire_for_left_clust_test_data = test_assembled_data{3}(all_test_comparisons(all_test_idxs,1));
rep_wire_for_left_clust_test_data_loc = locations(rep_wire_for_left_clust_test_data,:);
rep_wire_for_right_clust_test_data = test_assembled_data{3}(all_test_comparisons(all_test_idxs,2));
rep_wire_for_right_clust_test_data_loc = locations(rep_wire_for_right_clust_test_data,:);
test_euc_distance_between_rep_wires = vecnorm(rep_wire_for_left_clust_test_data_loc - rep_wire_for_right_clust_test_data_loc,2, 2);

%now assemble the test data
%training_data = [training_overlap,training_euc_distance_between_rep_wires,training_euc_distance_between_rep_wfs,training_left_col_size,training_right_col_size];
test_data = [test_overlap,test_euc_distance_between_rep_wires,test_euc_distance_between_rep_wfs];

%append the true class to the end of the test data
test_data = [test_data,[test_true_class(all_test_idxs)]];

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