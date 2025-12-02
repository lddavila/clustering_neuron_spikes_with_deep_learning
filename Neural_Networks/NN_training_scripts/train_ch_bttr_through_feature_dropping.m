function [] = train_ch_bttr_through_feature_dropping(varargin)
%this version of choose better will attempt to find the ideal features by
%pursuing a feature drop method
%we'll start by setting up a baseline performance metric by testing all
%features together
%then we'll try dropping a random feature
%if it improves then we'll drop another feature and repet
%if it decreases in accuracy on the test data then we'll put it back in
%and try dropping a different feature and repeating
%we'll do this until we find the minimum viable product
%in the case of no change in the accuracy which is rare but technically
%possible we'll drop the feature

[dir,name,ext] = fileparts(mfilename('fullpath'));
cd(dir);
home_dir = cd("..");
cd("..");
addpath(genpath(pwd))
cd(home_dir)
disp("Finished adding path");

%get the config
config = spikesort_config();
disp("Finished getting config");

%create a directory to save the results to
dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"ch_bttr_through_dropping"));
disp("Finished creating save dir");

%import the blind pass data we will use for trainining
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_6_to_10);
else
    blind_pass_table = varargin{1};
end
disp("Finshed loading blind pass directory");

%filter out any rows of blind pass table that have accuracy less than 1
%we do this because they are MUA and MUA are unpredictable and can make
%training unstable
blind_pass_table(blind_pass_table{:,"accuracy"}<1,:) = [];
disp("Finished filtering blind pass")

%first thing we can do is partition the blind pass table into
%testing/training data
partitioned_data = partition_bp_tables(blind_pass_table,0);
test_data = partitioned_data{2};
training_data = partitioned_data{1};


%now further partition training data into training and validation
partitioned_data = partition_bp_tables(training_data,0);
training_data = partitioned_data{1};
val_data = partitioned_data{2};
disp("Finished partitioning training/test/val data")

%this partition occurs at the unit level
%30 percent of of units are removed to validate/test
%if we didn't do this then the neural network could cheat by learning a
%particular unit's rough accuracy and then using that same information
%during validation

%set the features that will be used to train the neural net
list_of_features_to_add = ["grades 2","valley_1","valley_2"];

%get the features
training_features_array = assemble_data_for_neural_net(list_of_features_to_add,training_data,config);
training_features_array = cell2mat(training_features_array);
val_features_array = assemble_data_for_neural_net(list_of_features_to_add,val_data,config);
val_features_array = cell2mat(val_features_array);
test_features_array = assemble_data_for_neural_net(list_of_features_to_add,test_data,config);
test_features_array = cell2mat(test_features_array);

disp("Finished getting features");

%normalize all features based on trainining data
col_min = min(training_features_array,[],1);
col_max = max(training_features_array,[],1);

training_features_array = rescale(training_features_array,0,1,"InputMax",col_max,"InputMin",col_min);
val_features_array = rescale(val_features_array,0,1,"InputMax",col_max,"InputMin",col_min);
test_features_array = rescale(test_features_array,0,1,"InputMax",col_max,"InputMin",col_min);


%get every possible comparison
training_all_comparisons = nchoosek(1:(round(size(training_features_array,1) / 4)),2); %only for local debugging
val_all_comparisons = nchoosek(1:(round(size(val_features_array,1) / 4)),2); %only for local debugging
test_all_comparisons = nchoosek(1:(round(size(test_features_array,1) / 4)),2); %only for local debugging

%actual comparisons to be used on cluster
% training_all_comparisons = nchoosek(1:size(training_features_array,1),2);
% val_all_comparisons = nchoosek(1:size(val_features_array,1),2);
% test_all_comparisons = nchoosek(1:size(test_features_array,1),2);
disp("finished getting all train/val/test comparisons")

%get the true class for all the comparisons
%1 = the "left" cluster is better
%0 = the "right" cluster is better
train_true_class = training_data{training_all_comparisons(:,1),"accuracy"} > training_data{training_all_comparisons(:,2),"accuracy"};
val_true_class = val_data{val_all_comparisons(:,1),"accuracy"} > val_data{val_all_comparisons(:,2),"accuracy"};
test_true_class = test_data{test_all_comparisons(:,1),"accuracy"} > test_data{test_all_comparisons(:,2),"accuracy"};
disp("Finished getting true class");

% we'll also want to keep track of the magnitude of accuracy differences
%this is necessary because the very easy choices are simple for the neural
%network to make (large accuracy differrences are easy to identify)

%the goal is to find a general solution so we'll ensure that during
%training/validating/testing that there's an equal distribution of
%hard/easy cases hopefully preventing a misleading accuracy rate on test
%data
train_mag_differences = abs(training_data{training_all_comparisons(:,1),"accuracy"} - training_data{training_all_comparisons(:,2),"accuracy"});
val_mag_differences = abs(val_data{val_all_comparisons(:,1),"accuracy"} - val_data{val_all_comparisons(:,2),"accuracy"});
test_mag_differences = abs(test_data{test_all_comparisons(:,1),"accuracy"} - test_data{test_all_comparisons(:,2),"accuracy"});

%set some buckets of difficulty
difficulty_buckets = [0,1,5,10,20,30,40,50,60];

%add the difficulty category to all test/training/val comparisons
train_bucket = get_difficulty_buckets_array(train_mag_differences,difficulty_buckets);
val_buckets = get_difficulty_buckets_array(val_mag_differences,difficulty_buckets);
test_buckets = get_difficulty_buckets_array(test_mag_differences,difficulty_buckets);


%randomly sample the test/training/validation data to ensure that all
%difficulty classes are equally represented
[training_all_comparisons,train_true_class,~] = sample_data_by_difficulty_bucket(training_all_comparisons,train_true_class,train_bucket);
[val_all_comparisons,val_true_class,~] = sample_data_by_difficulty_bucket(val_all_comparisons,val_true_class,val_buckets);

%we won't do the same for test data because test data will be a truer
%representation of choose better since we don't actually know how many of
%each class will appear in actual data
%so the better it does on a non-equalized sample the better we can expect


%now comes the interesting part where we actually implement some logic to
%find the ideal feature set

%first we need to produce a list of all possible combinations of grades
%now using the max # of features AKA # of cols we can then calculate all
%possible permutations of those features
%order is not important because the neural network will be ambiguous to
%appearence of the arrays just this will create a very large set of
%permutations
list_of_feature_nums = 1:size(test_features_array,2);
cell_array_of_feature_combos = cell(length(list_of_feature_nums),1);

%start with all features since this will servce as our baseline
%we won't go all the way down to 1 feature because no single feature is so
%predictive
counter =1;
for i=length(list_of_feature_nums):-1:2
    cell_array_of_feature_combos{counter} = nchoosek(1:length(list_of_feature_nums),i);
    counter = counter+1;
end


size_of_all_combos = sum(cell2mat(cellfun(@size,cell_array_of_feature_combos,'UniformOutput',false)),1);
size_of_preallocation = size_of_all_combos(1);
%now we'll put the combinations into a table in order to use the parallel
%processing to it's fullest extent downstream
table_of_feature_combos = cell2table(cell(size_of_preallocation,1),'VariableNames',["feature_combo"]);
next_empty_row_tracker = 1;
for i=1:length(cell_array_of_feature_combos)
    current_list = cell_array_of_feature_combos{i};
    table_of_feature_combos{next_empty_row_tracker:next_empty_row_tracker+size(current_list,1)-1,"feature_combo"}= num2cell(current_list,2);
    next_empty_row_tracker = next_empty_row_tracker+size(current_list,1);
    disp(i)
end

%structure the table for parallel processing
% table_of_feature_combos = slice_table_for_parallel_processing(table_of_feature_combos,[]);
disp("Finished formatting table for parallel processing")
%navigate to the directory we'll be saving results to
cd(dir_to_save_results_to)
disp("finished navigating into save directory")
if ~isfile("all_feature_choose_better_net.mat")
    [default_net,baseline_test_accuracy] = repeatable_training_set_up(training_features_array, ...
        val_features_array, ...
        test_features_array, ...
        training_all_comparisons, ...
        val_all_comparisons, ...
        test_all_comparisons,1, ...
        table_of_feature_combos{1,"feature_combo"}{1}, ...
        train_true_class, ...
        val_true_class, ...
        test_true_class);

    
    net_struct = struct();
    net_struct.net = default_net;
    net_struct.column_min = col_min;
    net_struct.column_max = col_max;
    net_struct.baseline_test_accuracy = baseline_test_accuracy;

    par_save("all_feature_choose_better_net.mat",net_struct);
else
   load("all_feature_choose_better_net.mat","net_struct");
   default_net = net_struct.net;
   baseline_test_accuracy = net_struct.baseline_test_accuracy;
   col_min = net_struct.column_min;
   col_max = net_struct.column_max;
   disp("Finished loading default net")
end

fprintf("Baseline net accuracy is %.2f\n",baseline_test_accuracy*100);

%now we'll institute a parfor loop to iterate through as many neural
%network architectures as possible 
%now the main idea is that we're trying to weed out features which serve as
%poison pills or "snow" to the other features
%this will be accomplished by training neural networks with all features
%except for 1
%if the test accuracy decreases then we'll ensure that no neural network
%that is missing that particular feature will train again
%this will be accomplished by using a dataqueue to keep track of which
%features should never be removed
%any permutation of features that is missing items on this
%"never_remove_dataqueue" will be automatically skipped
%this will save on compute time
%it won't be perfect as sometimes new worker(s) will start before an old
%worker determines a feature cannot be dropped, 
never_remove_list = [];
for i=2:height(table_of_feature_combos)
    never_remove_list = unique(never_remove_list);
    current_features = table_of_feature_combos{i,"feature_combo"}{1};
    missing_features = setdiff(1:size(training_features_array,2),current_features);
    
    if any(ismember(missing_features,never_remove_list))
        continue;
    end
    [current_net,current_accuracy] = repeatable_training_set_up(training_features_array, ...
        val_features_array, ...
        test_features_array, ...
        training_all_comparisons, ...
        val_all_comparisons, ...
        test_all_comparisons,1, ...
        current_features,train_true_class,val_true_class,test_true_class);
    

    net_struct = struct();
    net_struct.net = current_net;
    net_struct.column_min = col_min;
    net_struct.column_max = col_max;
    net_struct.current_accuracy = current_accuracy;
    net_struct.missing_features = missing_features;
    net_struct.used_features = current_features;


    par_save("net_iteration"+string(i)+".mat",net_struct);
    
    if current_accuracy - baseline_test_accuracy < -0.05
        %if accuracy moves down by more than 5% then we'll assume we removed a
        %vitally important and add it to the never remove list
        never_remove_list = [never_remove_list;missing_features];
    end
end
end