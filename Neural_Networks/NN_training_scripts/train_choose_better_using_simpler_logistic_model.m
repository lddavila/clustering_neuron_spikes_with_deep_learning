function [] = train_choose_better_using_simpler_logistic_model(blind_pass_table,config)
%create a directory to save the trained models
dir_to_save_results = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"logistic_choose_better"));

%set rng for reproducability
rng(0)
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
disp("Finished getting certainties first time")

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

%take the first n samples of class 1 
n = 10000;
first_n_class_1_train = find(train_difficulty_data(:,end)==1,n);
not_class_1_train = find(train_difficulty_data(:,end)~=1);

first_n_class_1_test = find(test_difficulty_data(:,end)==1,n);
not_class_1_test = find(test_difficulty_data(:,end)~=1);

train_difficulty_data = train_difficulty_data([first_n_class_1_train;not_class_1_train],:);
test_difficulty_data = test_difficulty_data([first_n_class_1_test;not_class_1_test],:);


%equalize the difficulty classes in training and testing data
equalized_train_rows = equalize_classes(train_difficulty_data);
equalized_test_rows = equalize_classes(test_difficulty_data);



%assemble the comparison data
left_cluster_training = training_certainties(equalized_train_rows{:,1},:);
right_cluster_training = training_certainties(equalized_train_rows{:,2},:);

left_cluster_test = testing_certainties(equalized_test_rows{:,1},:);
right_cluster_test = testing_certainties(equalized_test_rows{:,2},:);


%assemble the true class for each comparison
train_true_class = blind_training{equalized_train_rows{:,1},"accuracy"} >blind_training{equalized_train_rows{:,2},"accuracy"}  ;
test_true_class = blind_test{equalized_test_rows{:,1},"accuracy"}  > blind_test{equalized_test_rows{:,2},"accuracy"} ;

possible_alphas = 0.1:.1:1;
possible_widths = 3:1:20;

%run through all possible window widths to see which alpha/window width
%produce the highest accuracy on the test data
counter = 1;
for i=1:length(possible_widths)
    current_width = possible_widths(i);
    train_left_cluster_window_averages = {};
    train_right_cluster_window_averages = {};
    for j=1:size(left_cluster_training,2)
        %we want our window to be rougly even if possible so we define the
        %beginning and end of our window to be centered at a certain
        %threshold j and take into account certainties on both sides
        window_beginning = max([1,j - round(current_width/2)]);
        window_end = min(j+round(current_width/2),size(left_cluster_training,2));

        %get the average certainty for the left cluster
        train_left_cluster_window_averages{end+1} = mean(left_cluster_training(:,window_beginning:window_end),2);
        train_right_cluster_window_averages{end+1} = mean(right_cluster_training(:,window_beginning:window_end),2);


    end

    test_left_cluster_window_averages = {};
    test_right_cluster_window_averages = {};
    for j=1:size(left_cluster_test,2)
        %we want our window to be rougly even if possible so we define the
        %beginning and end of our window to be centered at a certain
        %threshold j and take into account certainties on both sides
        window_beginning = max([1,j - round(current_width/2)]);
        window_end = min(j+round(current_width/2),size(left_cluster_test,2));

        %get the average certainty for the left cluster
        test_left_cluster_window_averages{end+1} = mean(left_cluster_test(:,window_beginning:window_end),2);
        test_right_cluster_window_averages{end+1} = mean(right_cluster_test(:,window_beginning:window_end),2);


    end

    train_flattened_left_window = cell2mat(train_left_cluster_window_averages);
    train_flattened_right_window = cell2mat(train_right_cluster_window_averages);

    test_flattened_left_window = cell2mat(test_left_cluster_window_averages);
    test_flattened_right_window = cell2mat(test_right_cluster_window_averages);


    %we'll derive some features that can we expect to be useful in
    %developing a model which can automatically determine which neural
    %network has a higher accuracy

    %the derivative of the certainty curves for each cluster
    train_dL = diff(train_flattened_left_window,1,2);
    train_dR = diff(train_flattened_right_window,1,2);

    test_dL = diff(test_flattened_left_window,1,2);
    test_dR = diff(test_flattened_right_window,1,2);



    %the min derivative value for the left/right clusters and the index of
    %where that falls
    %jL = where the certainty curve drops the fastest for the left cluster
    [train_minDL, train_jL] = min(train_dL,[],2);
    [test_minDL, test_jL] = min(test_dL,[],2);
    %jR = where the certainty curve drops the fastest for the right cluster
    [train_minDR, train_jR] = min(train_dR,[],2);
    [test_minDR,test_jR] = min(test_dR,[],2);

    %negative value indicates that the right cluster has higher accuracy
    %positive value indicates the left cluster has higher accuracy
    train_delta_j = train_jL - train_jR;
    test_delta_j = test_jL - test_jR;

    %sL and sR are measurements of how steep the cluster's certainty drop is
    %sharp drops means the certainty switched quickly from positive to
    %negative
    %shallow drops means that the transition was uncertain
    %a larger s indicates the estimate is more trustworthy
    train_sL = -train_minDL;
    train_sR = -train_minDR;
    test_sL = -test_minDL;
    test_sR = -test_minDR;
    %the difference between the sharpness of certainty drop
    train_delta_s = log((train_sL + eps) ./ (train_sR + eps));
    test_delta_s = log((test_sL + eps)./ (test_sR + eps));

    for j=1:length(possible_alphas)
        alpha = possible_alphas(j);
        train_TL = train_dL < alpha.*train_minDL;
        train_TR = train_dR < alpha.*train_minDR;

        test_TL = test_dL < alpha.*test_minDL;
        test_TR = test_dR < alpha.*test_minDR;


        %small widths mean the drop is concentrated, the estimate is precise,
        %and all the nets agree tightly
        train_wL = sum(train_TL,2);
        train_wR = sum(train_TR,2);
        test_wL = sum(test_TL,2);
        test_wR = sum(test_TR,2);
        %positive delta_w indicates the left cluster is more certain about its
        %decision that the right cluster
        train_delta_w = train_wR - train_wL;
        test_delta_w = test_wR - test_wL;


        X_train = [train_delta_j, train_delta_s, train_delta_w];
        X_test = [test_delta_j, test_delta_s, test_delta_w];
        mu = mean(X_train,1);
        sd = std(X_train,0,1);
        sd(sd==0) = 1;                     % avoid divide by zero


        Xtr = (X_train - mu)./sd;
        Xte = (X_test  - mu)./sd;

        B = glmfit(Xtr, train_true_class, 'binomial', 'link', 'logit');


        p = glmval(B, Xte, 'logit');
        pred = p > 0.5;
        acc = mean(pred == test_true_class);

        model_info.B = B;
        model_info.width = current_width;
        model_info.alpha = alpha;
        model_info.acc = acc;

        par_save(fullfile(dir_to_save_results,"binomial_model_accuracy_"+string(i)+"_"+string(j)+"_"+sprintf("%.2f",acc)+".mat"),model_info);
        fprintf("%i/%i\n",counter,length(possible_widths)*length(possible_alphas));
        counter = counter+1;
    end
end
end