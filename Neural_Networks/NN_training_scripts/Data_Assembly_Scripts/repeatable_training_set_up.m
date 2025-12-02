function [net,accuracy] = repeatable_training_set_up(training_features_array, ...
    val_features_array, ...
    test_features_array, ...
    training_all_comparisons, ...
    val_all_comparisons, ...
    test_all_comparisons,permutation_number, ...
    current_feature_combos, ...
    training_true_class, ...
    val_true_class, ...
    test_true_class)

layers_of_net = dynamically_create_layers_for_nn(length(current_feature_combos)*2,10,5,2);

%assemble the training, validation, and test data
training_data = [training_features_array(training_all_comparisons(:,1),current_feature_combos),training_features_array(training_all_comparisons(:,2),current_feature_combos)];
val_data = [val_features_array(val_all_comparisons(:,1),current_feature_combos),val_features_array(val_all_comparisons(:,2),current_feature_combos)];
test_data = [test_features_array(test_all_comparisons(:,1),current_feature_combos),test_features_array(test_all_comparisons(:,2),current_feature_combos)];

%concatenate the true class to all datasets
training_data = [training_data,training_true_class];
val_data = [val_data,val_true_class];
test_data = [test_data,test_true_class];

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
[~,net] = test_nn_on_incremental_challenging_specify_stop_fcn(training_data,val_data,layers_of_net,128,@stop_on_max_acc_and_lack_of_improvement);
% fprintf("Accuracy on training and validation data: %.2f\n",accuracy*100);

%take the trained net and see its performance on the testing data
%this performance is the truest indicator of performance
scores = predict(net,test_data(:,1:end-1));
[~,YPred] = max(scores,[],2);
YPred = YPred-1;

accuracy = sum(YPred==test_data(:,end))/size(test_data,1);

%print out a statement to reflect accuracy
fprintf("Accuracy on test data: %.2f for permutation :%i \n",accuracy*100,permutation_number);
end