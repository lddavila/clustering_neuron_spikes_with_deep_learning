function [] = train_ch_bttr_with_new_grades(varargin)
%set the path
[dir,name,ext] = fileparts(mfilename('fullpath'));
cd(dir);
home_dir = cd("..");
cd("..");
addpath(genpath(pwd))
cd(home_dir)

%get the config
config = spikesort_config();

%create a directory to save the results to 
dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"ch_bttr_with_valley"));

%import the blind pass data we will use for trainining
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_6_to_10);
else
    blind_pass_table = varargin{1};
end

%filter out any rows of blind pass table that have accuracy less than 1
%we do this because they are MUA and MUA are unpredictable and can make
%training unstable
blind_pass_table(blind_pass_table{:,"accuracy"}<1,:) = [];

%first thing we can do is partition the blind pass table into
%testing/training data
partitioned_data = partition_bp_tables(blind_pass_table,0);
test_data = partitioned_data{2};
training_data = partitioned_data{1};

%now further partition training data into training and validation
partitioned_data = partition_bp_tables(training_data,0);
training_data = partitioned_data{1};
val_data = partitioned_data{2};

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


%ideally we want to train a single neural network to be able to generally
%choose the cluster with higher accuracy
%this might prove difficult because the task gets harder the closer the
%accuracy gets

%to solve this we'll train via curriculum learning
%where it will be begin with trivial examples (huge differences in
%accuracy) 
%then make them closer and closer
%Ensuring to preserve some of the earlier examples in every harder example
%so that the neural net doesn't forget the early bits of training
%we will mix recordings 
    %recording with level 6 and level 10 noise are both in the training set

%get every possible comparison
training_all_comparisons = nchoosek(1:(round(size(training_features_array,1) / 5)),2); %only for local debugging
val_all_comparisons = nchoosek(1:(round(size(val_features_array,1) / 5)),2); %only for local debugging
test_all_comparisons = nchoosek(1:(round(size(test_features_array,1) / 5)),2); %only for local debugging

%actual comparisons to be used on cluster
training_all_comparisons = nchoosek(1:size(training_features_array,1),2); 
val_all_comparisons = nchoosek(1:size(val_features_array,1),2); 
test_all_comparisons = nchoosek(1:size(test_features_array,1),2);

%get the magnitude of the differences between their accuracy
train_acc_diff_mag = abs(training_data{training_all_comparisons(:,1),"accuracy"} - training_data{training_all_comparisons(:,2),"accuracy"});
val_acc_diff_mag = abs(val_data{val_all_comparisons(:,1),"accuracy"} - val_data{val_all_comparisons(:,2),"accuracy"});
test_acc_diff_mag = abs(test_data{test_all_comparisons(:,1),"accuracy"} - test_data{test_all_comparisons(:,2),"accuracy"});

%get the true class for all the comparisons
%1 = the "left" cluster is better
%0 = the "right" cluster is better
train_true_class = training_data{training_all_comparisons(:,1),"accuracy"} > training_data{training_all_comparisons(:,2),"accuracy"};
val_true_class = val_data{val_all_comparisons(:,1),"accuracy"} > val_data{val_all_comparisons(:,2),"accuracy"};
test_true_class = test_data{test_all_comparisons(:,1),"accuracy"} > test_data{test_all_comparisons(:,2),"accuracy"};

%remove the blind_pass_tables to save on memory
clear("blind_pass_table");
clear("training_data");
clear("val_data");
clear("test_data");

%define some accuracy magnitudes to define the differences
%curriculum thresholds are structured to the easiest ones appear in the
%beginning and the harder ones are towards the end
curriculum_thresholds= [70,60,50,45,40,35,30,25,20,15,10,5,1];

train_comparisons_to_preserve = cell(length(curriculum_thresholds),1);
train_true_class_of_preserved_comparisons = cell(length(curriculum_thresholds),1);
val_comparisons_to_preserve = cell(length(curriculum_thresholds),1);
val_true_class_of_preserved_comparisons = cell(length(curriculum_thresholds),1);
test_comparisons_to_preserve = cell(length(curriculum_thresholds),1);
test_true_class_of_preserved_comparisons = cell(length(curriculum_thresholds),1);

%set seed for reproducability
rng(0);

%get a neural network which we'll try to generalize
%now get a neural network which will be used to train the current task
%10=num neurons per layer
%5 = num layers
%2 = number of classes
%4 = number of features in assembled data
layers_of_net = dynamically_create_layers_for_nn(size(training_features_array,2)*2,10,5,2);

%navigate into the data to save to
cd(dir_to_save_results_to);
for i=1:length(curriculum_thresholds)
    %get comparisons which meet the current_curriculum thresholds
    if i==1
        [training_rows,~] = find(train_acc_diff_mag >= curriculum_thresholds(i));
        [val_rows,~] = find(val_acc_diff_mag >= curriculum_thresholds(i));
        [test_rows,~] = find(test_acc_diff_mag >= curriculum_thresholds(i));
    else
        [training_rows,~] = find(train_acc_diff_mag >= curriculum_thresholds(i) & train_acc_diff_mag < curriculum_thresholds(i-1));
        [val_rows,~] = find(val_acc_diff_mag >= curriculum_thresholds(i) & val_acc_diff_mag < curriculum_thresholds(i-1));
        [test_rows,~] = find(test_acc_diff_mag >= curriculum_thresholds(i) & test_acc_diff_mag < curriculum_thresholds(i-1));
    end

    if any([isempty(training_rows),isempty(val_rows),isempty(test_rows)])
        continue;
    end
    %now that we have comparisons that fall into our curriculum threshold
    %we should select those comparisons indexes in a local variable
    %remember in_curriculum_comparisons reference the actual rows in the
    %feature_array
    training_in_curriculum_comparisons_idxs = training_all_comparisons(training_rows,:);
    val_in_curriculum_comparison_idxs = val_all_comparisons(val_rows,:);
    test_in_curriculum_comparison_idxs = test_all_comparisons(test_rows,:);


    %now randomly take out 30% of comparisons for downstream training 
    %this ensures the neural network doesn't overwrite earlier lessons
    train_randomly_preserved_comparisons_idxs = randperm(size(training_in_curriculum_comparisons_idxs,1),round(size(training_in_curriculum_comparisons_idxs,1) * .3));
    train_comparisons_to_preserve{i} = training_in_curriculum_comparisons_idxs(train_randomly_preserved_comparisons_idxs,:);
    train_true_class_of_preserved_comparisons{i} = train_true_class(training_rows(train_randomly_preserved_comparisons_idxs,:));
    
    %do the same thing for validation data
    val_randomly_preserved_comparison_idxs = randperm(size(val_in_curriculum_comparison_idxs,1),round(size(val_in_curriculum_comparison_idxs,1)* .3));
    val_comparisons_to_preserve{i} = val_in_curriculum_comparison_idxs(val_randomly_preserved_comparison_idxs,:);
    val_true_class_of_preserved_comparisons{i} = val_true_class(val_rows(val_randomly_preserved_comparison_idxs,:));

    %repeat for the test data
    test_randomly_preserved_comparisons_idxs = randperm(size(test_in_curriculum_comparison_idxs,1),round(size(test_in_curriculum_comparison_idxs,1)*0.3));
    test_comparisons_to_preserve{i} = test_in_curriculum_comparison_idxs(test_randomly_preserved_comparisons_idxs,:);
    test_true_class_of_preserved_comparisons{i} = test_true_class(test_rows(test_randomly_preserved_comparisons_idxs,:));

    %now get the remaining idxs which will actually be used for training
    remaining_comparison_idxs = setdiff(1:size(training_in_curriculum_comparisons_idxs,1),train_randomly_preserved_comparisons_idxs);
    training_comparisons = training_in_curriculum_comparisons_idxs(remaining_comparison_idxs,:);
    
    %do the same for validation data
    val_remaining_comparison_idxs = setdiff(1:size(val_in_curriculum_comparison_idxs,1),val_randomly_preserved_comparison_idxs);
    val_comparisons = val_in_curriculum_comparison_idxs(val_remaining_comparison_idxs,:);

    %do the same for testing data
    test_remaining_comparison_idxs = setdiff(1:size(test_in_curriculum_comparison_idxs,1),test_randomly_preserved_comparisons_idxs);
    test_comparisons = test_in_curriculum_comparison_idxs(test_remaining_comparison_idxs,:);

    %we go to the extra step of preserving validation/testing data to
    %ensure that the validation and testing sets are made up a mixture of
    %difficuly choices, ensuring we don't lose earlier training during
    %later training



    %get the true class for the training data
    remaining_true_class = train_true_class(training_rows(remaining_comparison_idxs));

    %do the same for the validation data
    val_remaining_true_class = val_true_class(val_rows(val_remaining_comparison_idxs));

    %do the same for the test data
    test_remaining_true_class = test_true_class(test_rows(test_remaining_comparison_idxs));
    %append preserved comparisons and true class to the current data set
    if i~=1
        training_comparisons = [training_comparisons; cell2mat(train_comparisons_to_preserve(1:i-1))];
        remaining_true_class = [remaining_true_class;cell2mat(train_true_class_of_preserved_comparisons(1:i-1))];

        val_comparisons = [val_comparisons;cell2mat(val_comparisons_to_preserve(1:i-1))];
        val_remaining_true_class = [val_remaining_true_class;cell2mat(val_true_class_of_preserved_comparisons(1:i-1))];

        test_comparisons = [test_comparisons;cell2mat(test_comparisons_to_preserve(1:i-1))];
        test_remaining_true_class = [test_remaining_true_class;cell2mat(test_true_class_of_preserved_comparisons(1:i-1))];


    end

    %assemble the training, validation, and test data
    training_data = [training_features_array(training_comparisons(:,1),:),training_features_array(training_comparisons(:,2),:)];
    val_data = [val_features_array(val_comparisons(:,1),:),val_features_array(val_comparisons(:,2),:)];
    test_data = [test_features_array(test_comparisons(:,1),:),test_features_array(test_comparisons(:,2),:)];

    %concatenate the true class to all datasets
    training_data = [training_data,remaining_true_class];
    val_data = [val_data,val_remaining_true_class];
    test_data = [test_data,test_remaining_true_class];

    %equalize 0/1 classes
    training_data = equalize_classes(training_data);
    val_data = equalize_classes(val_data);
    test_data = equalize_classes(test_data);

    %print out how many of each class there are in training
    disp("Number of 0 class "+string(sum(training_data(:,end)==0)))
    disp("Number of 1 class "+string(sum(training_data(:,end)==1)))
    
    %now shuffle the rows
    training_data = training_data(randperm(size(training_data,1),size(training_data,1)),:);

    %now train
    [accuracy,net] = test_nn_on_incremental_challenging(training_data,val_data,layers_of_net,32);
    fprintf("Accuracy on training and validation data: %.2f\n",accuracy*100);

    %take the trained net and see its performance on the testing data
    %this performance is the truest indicator of performance
    scores = predict(net,test_data(:,1:end-1));
    [~,YPred] = max(scores,[],2);
    YPred = YPred-1;

    accuracy = sum(YPred==test_data(:,end))/size(test_data,1);

    %print out a statement to reflect accuracy
    fprintf("Accuracy on test data: %.2f\n for curriculum threshold:%i ",accuracy*100,curriculum_thresholds(i));
    %save the net to preserve the accuracy for future
    par_save("difference_in_stage_"+string(i)+"_test_acc_"+sprintf('%f',accuracy)+".mat",net);
end
end