%% import the blind pass table that we need
blind_pass_table = importdata("F:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\blind_pass_table.mat");

%% get config and overwrite the parent save dir
config = spikesort_config();
config.parent_save_dir = "F:";

%% create a directory to save the results
dir_to_save_results = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"testing_choose_better"));

%% set rng for reproducability
rng(0)

%% get the raw data required for the neural network
list_of_features_to_add = ["grades 3"];
grades_array = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table  ,config))];

%% get a table which displays all the nets that we will use
table_of_nets = struct2table(dir(fullfile(config.dir_of_prob_dist_nets,"*.mat")));
net_names = string(table_of_nets.name);
split_net_names = split(net_names,"_");
[~,where_below_ends ]= find(split_net_names=="below");
net_nums = arrayfun(@(i) split_net_names(i, where_below_ends(i)+1), ...
    (1:size(split_net_names,1))');

%% sort the nets by their threshold so that we have an ordered list of thresholds
table_of_nets.threshold = str2double(net_nums);
table_of_nets = sortrows(table_of_nets,"threshold","ascend");

%get the all the certainties for the all the grades
[~,unscaled_certainties ]= get_certainties_of_all_previous_nets(string(table_of_nets.name),config.dir_of_prob_dist_nets,grades_array);
disp("Finished getting certainties first time")
%% Filter by the first 5 nets
%use the first 5 nets
%those first 5 are trained to identify above/below thresholds [1, 2, 3, 4, 5]
%while none of the nets are 100% accurate they all have 88%+ accuracy
%we will take the consensus of their outputs as a way to filter out
%clusters that have less than 5% accuracy
first_five_certainties = unscaled_certainties(:,1:5);

%unscaled_certainties is a nx91 array where each value ranges between [-1,1]
%n: number of rows in blind_pass_table
%91: the number of thresholds that we have a neural network to identify
%above/below
%network 1 is for threshold 1
%network 2 is for threshold 2
%...
%network 91 is for threshold 91
%Certainty Close to 1 : indicates the network i is highly certain that row n has a higher
% accuracy than threshold i
%Certainty Close to -1: indicates the network i is highly certain that row n has a lower
% accuracy than threshold i
%Certainty Close to 0: indicates the network is not certain one way or
%the other

%if the majority of the first 5 networks all determine with a high degree of certainty
%that the example is above the first 5 thresholds then we can likely mark
%it as MUA and continue
elimination_condition =~(sum(first_five_certainties>=.9,2)>3);
blind_pass_table(elimination_condition, :) = [];
unscaled_certainties(elimination_condition,:) = [];
disp("Determined that "+string(sum(elimination_condition,"all"))+" were MUA and eliminated them from process")

%% 
%split the blind pass table into testing/training data to ensure that
%clusters seen during training do not leak into testing data artificially
%inflating the accuracy
pt_table  = partition_bp_tables(blind_pass_table,0);
blind_training = pt_table{1,1};
blind_test = pt_table{1,2};
%get certainties on a training/test level
%[~,unscaled_certainties ]= get_certainties_of_all_previous_nets(string(table_of_nets.name),config.dir_of_prob_dist_nets,grades_array);
training_grades = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_training,config))];
training_certainties = get_certainties_of_all_previous_nets(string(table_of_nets.name),config.dir_of_prob_dist_nets,training_grades);
disp("Finished getting training certainties");

testing_grades = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_test,config))];
testing_certainties = get_certainties_of_all_previous_nets(string(table_of_nets.name),config.dir_of_prob_dist_nets,testing_grades);
disp("Finished getting testing certainties");


%get all training/test comparisons
training_comparison_idxs = 1:size(training_certainties,1);
training_combinations = nchoosek(training_comparison_idxs,2);

test_comparison_idxs = 1:size(testing_certainties,1);
test_combinations = nchoosek(test_comparison_idxs,2);

%get the accuracy differences between the test and training comparisons
train_abs_acc_diff = abs(blind_training{training_combinations(:,1),"accuracy"} - blind_training{training_combinations(:,2),"accuracy"});
test_abs_acc_diff = abs(blind_test{test_combinations(:,1),"accuracy"} - blind_test{test_combinations(:,2),"accuracy"});

%assign some difficuly bins
difficulty_bins = [0,5,10,15,20,25,30,35,40,Inf];
train_difficulty_bin_id = get_difficulty_buckets_array(train_abs_acc_diff,difficulty_bins);
test_difficuly_bin_id = get_difficulty_buckets_array(test_abs_acc_diff,difficulty_bins);

%assemble comparisons together with difficulty level
train_difficulty_data = [training_combinations,train_difficulty_bin_id];
test_difficulty_data = [test_combinations,test_difficuly_bin_id];

%remove any nans
train_difficulty_data(any(isnan(train_difficulty_data),2),:) = [];
test_difficulty_data(any(isnan(test_difficulty_data),2),:) = [];