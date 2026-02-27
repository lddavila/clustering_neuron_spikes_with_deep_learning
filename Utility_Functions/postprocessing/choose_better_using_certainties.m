function [] = choose_better_using_certainties(blind_pass_table,config,varargin)

%check if the gt accuracy is available
%knowing this is available will allow us to visualize if requested
accuracy_available = ismember("accuracy",string(blind_pass_table.Properties.VariableNames));

%set some values to default if they aren't passed
if isempty(varargin)
    running_test = false;
    get_statistics = false;
else
    running_test_loc = find(ismember(string(varargin),"running_test"));
    running_test = varargin{running_test_loc+1};
    get_statistics_loc = find(ismember(string(varargin),"get_statistics"));
    get_statistics = varargin{get_statistics_loc+1};
end

%get the raw data required for the neural network
list_of_features_to_add = ["grades 3"];
grades_array = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config))];

%get a table which displays all the nets that we 
table_of_nets = struct2table(dir(fullfile(config.dir_of_prob_dist_nets,"*.mat")));
net_names = string(table_of_nets.name);
split_net_names = split(net_names,"_");
[~,where_below_ends ]= find(split_net_names=="below");
net_nums = arrayfun(@(i) split_net_names(i, where_below_ends(i)+1), ...
    (1:size(split_net_names,1))');

%sort the nets by their threshold so that we have an ordered list of
%thresholds
table_of_nets.threshold = str2double(net_nums);
table_of_nets = sortrows(table_of_nets,"threshold","ascend");

%get the all the certainties for the all the grades
[~,unscaled_certainties ]= get_certainties_of_all_previous_nets(string(table_of_nets.name),config.dir_of_prob_dist_nets,grades_array);

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

%if it is only a test function then we'll do some additional setup work
if running_test
    %get all possible comparisons
    blind_pass_idxs = 1:size(blind_pass_table,1);
    all_possible_combinations = nchoosek(blind_pass_idxs,2);

    %get the difference in accuracy between all the examples
    abs_acc_diff = abs(blind_pass_table{all_possible_combinations(:,1)  ,"accuracy"} - blind_pass_table{all_possible_combinations(:,2),"accuracy"});

    %assign some difficulty bins
    difficulty_bins = [0,5,10,15,20];
    difficulty_bin_id = get_difficulty_buckets_array(abs_acc_diff,difficulty_bins);

    %get only the first 20 samples of the first difficuly bin
    idx_of_first_20_samples = find(difficulty_bin_id==1,20);
    non_example_one = find(difficulty_bin_id~=1);
    %select the first 20 samples of the difficulty 1 class and combine them
    %with the remaining comparisons samples
    difficulty_bin_data = [all_possible_combinations([idx_of_first_20_samples;non_example_one],:), difficulty_bin_id([idx_of_first_20_samples;non_example_one])];

    %remove any rows with NaNs;
    difficulty_bin_data(any(isnan(difficulty_bin_data),2),:) = [];
    %now equally sample the comparisons
    %due to our previous data selection we should have at most 20 samples
    %for each dificulty class
    equalized_class_data = equalize_classes(difficulty_bin_data);

    %get the unique rows of blind pass table that make up the equalized
    %subset comparison
    unique_rows = unique([equalized_class_data{:,1}.',equalized_class_data{:,2}.']);
    blind_pass_table = blind_pass_table(unique_rows,:);
    unscaled_certainties = unscaled_certainties(unique_rows,:);
end

%now we can get all the comparisons of the blind pass table members
all_comparisons = nchoosek(1:size(unscaled_certainties,1),2);

%it should now simply be a matter of finding which comparison has the
%lowest certainty as far the right as possible
left_cluster_certainties = unscaled_certainties(all_comparisons(:,1),:);
right_cluster_certainties = unscaled_certainties(all_comparisons(:,2),:);

[~,left_cluster_min_idx] = min(left_cluster_certainties,[],2); 
[~,right_cluster_min_idx] = min(right_cluster_certainties,[],2); 

is_left_better_expected = left_cluster_min_idx > right_cluster_min_idx;




if accuracy_available && get_statistics
    is_left_better_true = blind_pass_table{all_comparisons(:,1),"accuracy"} > blind_pass_table{all_comparisons(:,2),"accuracy"};
    disp("Choose Better Accuracy");
    disp(sum(is_left_better_true==is_left_better_expected)/length(is_left_better_true));
elseif ~accuracy_available && get_statistics
    disp("The submitted blind pass talbe does not have the accuracy column thus the ground truth statistics cannot be computed");
end