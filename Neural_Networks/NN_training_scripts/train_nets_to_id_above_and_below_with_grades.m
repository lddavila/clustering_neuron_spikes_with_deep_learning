function [] = train_nets_to_id_above_and_below_with_grades(varargin)
%the goal of this function will be to test a new approach of predicting
%accuracy 
%instead of training a single neural network to accurately predict the
%accuracy category we'll train multiple neural networks at different
%thresholds to see if they are above/below certain accuracy categories
%the hypotehsis is that this will improve the final accuracy
%and the probabilities produced by these nets might be very important
%features when training choose better

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
dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"above_below_nets_better_increments"));

%import the blind pass data we will use for trainining
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_6_to_10);
else
    blind_pass_table = varargin{1};
end

%define the increments that the neural network will function for
thresholds = [1,5,10,15,20,30,40,50,60,70,80,90];
cd(dir_to_save_results_to)
for i=1:length(thresholds)
    current_threshold = thresholds(i);

    %partition the blind_pass_table into training and testing data
    partitioned_table_array = partition_bp_tables(blind_pass_table,0);
    testing_table = partitioned_table_array{1,2};
    training_table = partitioned_table_array{1,1};
    
    %parition the training table into training and validation data
    partitioned_training_table = partition_bp_tables(training_table,0);
    training_table = partitioned_training_table{1,1};
    val_table = partitioned_training_table{1,2};

    %partition the training data into above and below thresholds
    above_threshold_samples = training_table(training_table{:,"accuracy"}>current_threshold,:);
    below_threshold_samples = training_table(training_table{:,"accuracy"}<=current_threshold,:);

    %get the min number of samples we'll have per class
    min_num_samples_per_class = min([size(above_threshold_samples,1),size(below_threshold_samples,1),10000]);

    rng(0);

    %randomly sample the above/below
    random_above_indexes = randperm(size(above_threshold_samples,1),min_num_samples_per_class);
    random_below_indexes = randperm(size(below_threshold_samples,1),min_num_samples_per_class);


    %combine the data into a single dataset
    training_data = [above_threshold_samples(random_above_indexes,:);below_threshold_samples(random_below_indexes,:)];

    %shuffle the rows
    training_data = training_data(randperm(size(training_data,1),size(training_data,1)),:);
    
    %get the above/below class from the training table 0=below or equal to
    %and 1 means strictly above
    training_above_below_class = training_data{:,"accuracy"} > current_threshold;

    %extract the data required for training
    list_of_features_to_add = ["grades 2"];
    training_data = cell2mat(assemble_data_for_neural_net(list_of_features_to_add,training_data,config));

    %rescale the data between -1,1 to aid in convergence 
    %preserve the col min/max in order to rescale the validation/testing
    %data in a consistent way
    col_min = min(training_data,[],1);
    col_max = max(training_data,[],1);
    training_data = rescale(training_data,-1,1,"InputMax",col_max,"InputMin",col_min);
    %now get a neural network which will be used to train the current task
    %10=num neurons per layer
    %5 = num layers
    %2 = number of classes
    %4 = number of features in assembled data
    layers_of_net = dynamically_create_layers_for_nn(size(training_data,2),10,5,2);

    %append the true class to the end of training data
    training_data = [training_data,training_above_below_class];

    %get the validation data
    val_data = cell2mat(assemble_data_for_neural_net(list_of_features_to_add,val_table,config));
    %rescale the validation data based on the training data
    val_data = rescale(val_data,-1,1,"InputMax",col_max,"InputMin",col_min);
    %get validation data true class
    val_above_below_class = val_table{:,"accuracy"} > current_threshold;
    %append the class to val_data
    val_data = [val_data,val_above_below_class];



    %now train
    %now we can begin training
    if ~isfile("above_below_"+string(current_threshold)+".mat")
        % fprintf("Training to id above and below %i% accuracy threshold \n",current_threshold);
        % disp("");
        [accuracy,net] = test_nn_on_incremental_challenging(training_data,val_data,layers_of_net,32);
        fprintf("Accuracy on training and validation data: %.2f",accuracy*100);
        %save the data into a struct to preserve the input min/max
        net_struct = struct();
        net_struct.net = net;
        net_struct.InputMax = col_max;
        net_struct.InputMin = col_min;
        par_save("above_below_"+string(current_threshold)+"_accuracy_"+string(accuracy*100)+".mat",net_struct);
    else
        net_struct = importdata("above_below_"+string(current_threshold)+".mat");
        col_max = net_struct.InputMax;
        col_min = net_struct.InputMin;
        net = net_struct.net;
    end



    %now we'll test to see how well this does testing on above/below the
    %current accuracy thresholds on examples it has never seen before

    test_data = cell2mat(assemble_data_for_neural_net(list_of_features_to_add,testing_table,config));
    
    %rescale the data to match the training
    test_data =rescale(test_data,-1,1,"InputMax",col_max,"InputMin",col_min);

    %get the true class for test data
    test_true_class = testing_table{:,"accuracy"} >current_threshold;

    %append true test class to test data
    test_data = [test_data,test_true_class];

    %now get the predictions
    %now test the trained neural network on never before seen comparisons
    scores = predict(net,test_data(:,1:end-1));
    [~,YPred] = max(scores,[],2);
    YPred = YPred-1;

    accuracy = sum(YPred==test_data(:,end))/size(test_data,1);

    %print out a statement to reflect accuracy
    fprintf("Accuracy on test data: %.2f\n",accuracy*100);

end
end