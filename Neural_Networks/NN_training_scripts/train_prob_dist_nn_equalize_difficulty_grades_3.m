function [] = train_prob_dist_nn_equalize_difficulty_grades_3(varargin)
%the goal of this function is to use the neural network thresholding idea
%at every possible accuracy
%what we have observed in the past is that choose better will always fail
%once the two samples are closer to each other
%ie Cluster A is 55% accurate and Cluster B is 56% accuracte then choose
%better will fail
%Now this shouldn't matter, who cares about a 1% difference anyway
%the problem is getting them in the right pots
%ie make sure that all clusters within the 90-100% accurate pot are only
%being compared to clusters in the same pot
%We'll accomplish by training a series of neural networks to identify the
%above/below probabilities at every possible accuracy threshold
%ie 1%, 2%, 3%, ... 99%, 100% accurate
%Using the fact that we know that choose better fails when the accuracies
%are very close we can also assume that the degree of certainty each neural
%network produces will gradually decrease as it approaches the true
%accuracy and will increase once it gets father away from true accuracy

[dir,~,~] = fileparts(mfilename('fullpath'));
cd(dir);
home_dir = cd("..");
cd("..");
addpath(genpath(pwd))
cd(home_dir)
disp("Finished adding path");

config = spikesort_config();
disp("Finished getting config");

dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(config.parent_save_dir,"probability_distr_nets_equalized_difficulty_grades_3"));
% --- Load blind pass table ---
if nargin < 1
    blind_pass_table = importdata(config.FP_TO_EVEN_NUMBERED_RECORDINGS);
else
    blind_pass_table = varargin{1};
end
disp("Finished loading blind pass table");




list_of_features_to_add = ["grades 3"];
%define the increments that the neural network will function for
thresholds = 1:1:100;
cd(dir_to_save_results_to)

%partition the blind_pass_table into training and testing data
partitioned_table_array = partition_bp_tables(blind_pass_table,0);
testing_table = partitioned_table_array{1,2};
training_table = partitioned_table_array{1,1};

%parition the training table into training and validation data
partitioned_training_table = partition_bp_tables(training_table,0);
training_table = partitioned_training_table{1,1};
val_table = partitioned_training_table{1,2};



for i=1:length(thresholds)
    current_threshold = thresholds(i);

    thresh_mag_diff = abs(training_table{:,"accuracy"}-current_threshold);
    %set some buckets of difficulty to equalize by difficulty later
    difficulty_buckets = [0,5,10,15,20,25];

    training_diff_buckets = get_difficulty_buckets_array(thresh_mag_diff,difficulty_buckets,1);
    training_table.difficulty_buckets = training_diff_buckets;

    %remove any training table rows with NAN
    training_table(isnan(training_table{:,"difficulty_buckets"}),:) = [];

    equalized_training_table = equalize_classes(training_table);


    %partition the training data into above and below thresholds
    above_threshold_samples = equalized_training_table(equalized_training_table{:,"accuracy"}>current_threshold,:);
    below_threshold_samples = equalized_training_table(equalized_training_table{:,"accuracy"}<=current_threshold,:);





    %get the min number of samples we'll have per class
    try
        min_num_samples_per_class = min([size(above_threshold_samples,1),size(below_threshold_samples,1)]);

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
        training_data = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,training_data,config))];

        %remove any rows that have a nan
        nan_rows = any(isnan(training_data),2);
        training_data(nan_rows,:) = [];
        training_above_below_class(nan_rows,:)= [];

        tabulate(training_above_below_class);

        



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


        %we don't equalize val data because there's no guarantee of
        %probability in the real scenario
        val_data = rescale(val_data,-1,1,"InputMax",col_max,"InputMin",col_min);
        %get validation data true class
        val_above_below_class = val_table{:,"accuracy"} > current_threshold;
        %append the class to val_data
        val_data = [val_data,val_above_below_class];



        %now train
        %now we can begin training
        % fprintf("Training to id above and below %i% accuracy threshold \n",current_threshold);
        % disp("");
        [accuracy,net] = test_nn_on_incremental_challenging(training_data,val_data,layers_of_net,32);
        % fprintf("Accuracy on training and validation data: %.2f",accuracy*100);






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

        brier_score = mean((scores(:,2) - test_data(:,end)).^2);
        [~,~,~,auc] = perfcurve(test_data(:,end), scores(:,2), 1);

        %print out a statement to reflect accuracy
        % fprintf("Accuracy on test data: %.2f\n",accuracy*100);

        %print out a statement to reflect accuracy
        fprintf("Accuracy on test data: %.2f\n",accuracy*100);

        %save the data into a struct to preserve the input min/max
        net_struct = struct();
        net_struct.net = net;
        net_struct.InputMax = col_max;
        net_struct.InputMin = col_min;
        net_struct.brier_score = brier_score;
        net_struct.auc = auc;
        par_save("above_below_"+string(current_threshold)+"_"+"accuracy_"+sprintf("%.2f",accuracy*100)+".mat",net_struct);
    catch ME
        fprintf(2, getReport(ME, 'extended', 'hyperlinks', 'on'));

    end

end

end