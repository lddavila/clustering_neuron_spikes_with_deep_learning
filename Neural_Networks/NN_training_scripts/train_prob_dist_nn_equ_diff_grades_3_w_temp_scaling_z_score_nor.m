function [] = train_prob_dist_nn_equ_diff_grades_3_w_temp_scaling_z_score_nor(varargin)
%the goal of this function is to use the neural network thresholding idea
%at every possible accuracy
%we know that neural networks are very successful when there is a large
%difference between the true accuracy and the threshold that the neural
%network is trained to identify
%ie if cluster has Accuracy 80% and the neural network is meant to predict
%whether the cluster is above or below 1% accuracy then it will identify
%with 90% accuracy that the cluster is above 1% accuracy
%however for neural network's whose threshold is near the true accuracy
%i.e. if the neural network that's trained with the threshold 79% accuracy
%will be highly inaccurate with uncertainty being high
%probability of above = .5
%probability of below = .5
%using this phenomena we'll train neural networks at every accuracy
%threshold
%then we can identify the starting point of uncertainty and the ending
%point of uncertainty as a reasonable window which approximates the
%accuracy of the cluster

[the_dir,~,~] = fileparts(mfilename('fullpath'));
cd(the_dir);
home_dir = cd("..");
cd("..");
addpath(genpath(fullfile(pwd,"Utility_Functions")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Grading_scripts")));
addpath(genpath(fullfile(pwd,"Neural_Networks")));
cd(home_dir)
disp("Finished adding path");

config = spikesort_config();
disp("Finished getting config");

dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(config.parent_save_dir,"probability_distr_nets_equalized_difficulty_grades_3_with_temp_scaling_07_27_2026"));
dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(config.parent_save_dir,"probability_distr_nets_equalized_difficulty_grades_3_with_temp_scaling_09_23_2026"));
% --- Load blind pass table ---
if nargin < 1
    if contains(pwd,"10595")
        blind_pass_table = load("\hierarchy_training_table.mat");
        blind_pass_table = blind_pass_table.hierarchy_training_table;
        bp_4_ch = load("\from_ls6\4_ch\blind_pass_table\blind_pass_table.mat");
        bp_4_ch = bp_4_ch.data_to_save;
        only_cols = string(blind_pass_table.Properties.VariableNames);
        blind_pass_table = [blind_pass_table;bp_4_ch(:,only_cols)];
    else
        blind_pass_table = importdata(config.FP_TO_EVEN_NUMBERED_RECORDINGS);
    end
else
    blind_pass_table = varargin{1};
end
disp("Finished loading blind pass table");




list_of_features_to_add = ["grades 3"];
formatted_grades = cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config));
blind_pass_table = [blind_pass_table(:,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy"]),table(formatted_grades,'VariableNames',["grades"])];
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


last_net_names = [];
%rescale the data to aid in convergence
%this performs a z score normalization replaces invalid or missing
%values with 0, we do this cause of the variable number of channels
[training_table,testing_table,val_table,~,mu,sigma] = normalize_the_data(training_table,"current_test",testing_table,"current_val",val_table);
if contains(pwd,"10595")
    % Delete any active parallel pool
    delete(gcp('nocreate'));

    % Start a new pool with fewer workers (e.g., 4 workers)
    parpool(40);
end
parfor i=1:length(thresholds)
    already_done_nets = struct2table(dir(fullfile(dir_to_save_results_to,"*.mat")));
    current_threshold = thresholds(i);
    if any(contains(string(already_done_nets.name),"above_below_"+string(current_threshold)+"_"+"accuracy_"))
        continue;
    end
    rng(0)

    local_training_table = training_table(:,:);
    thresh_mag_diff = abs(local_training_table{:,"accuracy"}-current_threshold);
    %set some buckets of difficulty to equalize by difficulty later
    difficulty_buckets = [0,5,10,15,20,25,Inf];

    training_diff_buckets = get_difficulty_buckets_array(thresh_mag_diff,difficulty_buckets,1);
    local_training_table.difficulty_buckets = training_diff_buckets;

    %remove any training table rows with NAN
    local_training_table(isnan(local_training_table{:,"difficulty_buckets"}),:) = [];

    equalized_training_table = equalize_classes(local_training_table);


    %partition the training data into above and below thresholds
    above_threshold_samples = equalized_training_table(equalized_training_table{:,"accuracy"}>current_threshold,:);
    below_threshold_samples = equalized_training_table(equalized_training_table{:,"accuracy"}<=current_threshold,:);





    %get the min number of samples we'll have per class
    % try
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
    training_data = training_data.grades;

    %remove any rows that have a nan
    nan_rows = any(isnan(training_data),2);
    % training_data(nan_rows,:) = [];
    % training_above_below_class(nan_rows,:)= [];

    tabulate(training_above_below_class);

    

    if i~=1
        %if not on the first neural network then we'll use the certainty
        %from the last net as a feature in the next net
        %this will hopefully be a usefull feature
        % training_data = get_certainties_of_all_previous_nets(last_net_names,dir_to_save_results_to,training_data,"use_z_score",true);
    end

    

    

    %now get a neural network which will be used to train the current task
    %10=num neurons per layer
    %5 = num layers
    %2 = number of classes
    %4 = number of features in assembled data
    layers_of_net = dynamically_create_layers_for_nn(size(training_data,2),10,5,2);


    %append the true class to the end of training data
    training_data = [training_data,training_above_below_class];

    %get the validation data
    val_data = val_table.grades;

    %get test data
    test_data = testing_table.grades;


    

    if i~=1
        %if not on the first neural network then we'll use the certainty
        %from the last net as a feature in the next net
        %this will hopefully be a usefull feature
        % val_data = get_certainties_of_all_previous_nets(last_net_names,dir_to_save_results_to,val_data,"use_z_score",true);
        
        % test_data = get_certainties_of_all_previous_nets(last_net_names,dir_to_save_results_to,test_data,"use_z_score",true);
    end

    %rescale the validation data based on the training data
    %we don't equalize val data because there's no guarantee of
    %probability in the real scenario
    % val_data = rescale(val_data,0,1,"InputMax",col_max,"InputMin",col_min);

    %rescale the test data to match the training
    % test_data =rescale(test_data,0,1,"InputMax",col_max,"InputMin",col_min);
    
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

    % --- Fit temperature on validation data (post-hoc calibration) ---
    %remove any rows from val data that have nan
    val_data(any(isnan(val_data),2),:) = [];
    val_scores = predict(net, val_data(:,1:end-1));   % Nx2 probs
    val_p1 = val_scores(:,2);                         % prob of class "1" (above threshold)
    val_y  = val_data(:,end);                         % 0/1 labels

    %

    T = fit_temperature_binary(val_p1, val_y);

    % Optional: report calibration improvement on validation
    val_p1_cal = apply_temperature_binary(val_p1, T);
    
    val_brier_uncal = mean((val_p1 - val_y).^2);
    val_brier_cal   = mean((val_p1_cal - val_y).^2);
    fprintf("Threshold %d: fitted T=%.3f | Val Brier: %.4f -> %.4f\n", ...
        current_threshold, T, val_brier_uncal, val_brier_cal);




    %now we'll test to see how well this does testing on above/below the
    %current accuracy thresholds on examples it has never seen before

    

    

    %get the true class for test data
    test_true_class = testing_table{:,"accuracy"} >current_threshold;

    %append true test class to test data
    test_data = [test_data,test_true_class];

    %remove any rows that have nan
    % test_data(any(isnan(test_data),2))  = [];

    %now get the predictions
    %now test the trained neural network on never before seen comparisons
    scores = predict(net,test_data(:,1:end-1));    % Nx2 uncalibrated probs

    % Calibrate only the positive class probability; derive the negative prob
    p1_uncal = scores(:,2);
    p1_cal   = apply_temperature_binary(p1_uncal, T);
    scores_cal = [1 - p1_cal, p1_cal];

    % Hard predictions (optional): this will usually be unchanged unless p crosses 0.5
    YPred = scores_cal(:,2) >= 0.5;

    accuracy = mean(YPred == test_data(:,end));

    % Calibration-aware metrics should use calibrated probs
    brier_score = mean((p1_cal - test_data(:,end)).^2);
    [~,~,~,auc] = perfcurve(test_data(:,end), p1_cal, 1);

    %print out a statement to reflect accuracy
    % fprintf("Accuracy on test data: %.2f\n",accuracy*100);

    %print out a statement to reflect accuracy
    fprintf("Accuracy on test data: %.2f\n",accuracy*100);

    %save the data into a struct to preserve the input min/max
    net_struct = struct();
    net_struct.net = net;
    net_struct.mu = mu;
    net_struct.sigma = sigma;
    net_struct.brier_score = brier_score;
    net_struct.auc = auc;
    net_struct.temperature = T;
    last_net_name = "above_below_"+string(current_threshold)+"_"+"accuracy_"+sprintf("%.2f",accuracy*100)+".mat";
    par_save(last_net_name,net_struct);
    % last_net_names = [last_net_names,last_net_name];
    
end

end






