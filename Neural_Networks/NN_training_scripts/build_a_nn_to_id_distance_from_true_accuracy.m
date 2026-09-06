function [] = build_a_nn_to_id_distance_from_true_accuracy(options)
arguments
    options.unscaled_certainties double = []
    options.distance_from_min_uncertainty double = []
    options.filtered_bp_table table = []
end

home_dir = cd("..");
cd("..");
addpath(genpath(fullfile(pwd,"Neural_Networks/"))); 
addpath(genpath(fullfile(pwd,"Grading_scripts")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Utility_Functions")));
cd(home_dir);

config = spikesort_config();
if isempty(options.unscaled_certainties) && isempty(options.distance_from_min_uncertainty) && isempty(options.filtered_bp_table)
    unscaled_certainties = importdata(config.data_dir,"data_for_checking_certainty_stability","unscaled_certainties.mat");
    distance_from_min_uncertainty = importdata(config.data_dir,"data_for_checking_certainty_stability","distance_from_min_uncertainty.mat");
    filtered_bp_table = importdata(config.data_dir,"data_for_checking_certainty_stability","filtered_bp_table.mat");
else
    unscaled_certainties = options.unscaled_certainties;
    distance_from_min_uncertainty = options.distance_from_min_uncertainty;
    filtered_bp_table = options.filtered_bp_table;
end

bin_sizes = [0,5,10,20,30,40,100];
discretized_distance = discretize(distance_from_min_uncertainty,bin_sizes);



table_to_split = table(unscaled_certainties,discretized_distance,filtered_bp_table{:,"Max_Overlap_Unit"},'VariableNames',["unscaled_certainties","discretized_distance","Max_Overlap_Unit"]);

%partition the blind_pass_table into training and testing data
partitioned_table_array = partition_bp_tables(table_to_split,0);
testing_table = partitioned_table_array{1,2};
training_table = partitioned_table_array{1,1};

%partition the training table into training and validation data
partitioned_training_table = partition_bp_tables(training_table,0);
training_table = partitioned_training_table{1,1};
val_table = partitioned_training_table{1,2};

%when training we want equal sizes for each category as we don't want to
%bias the model towards any single category
per_cat_tr = groupcounts(training_table,"discretized_distance");
min_cat = min(per_cat_tr.GroupCount);

%randomly sample each category to match the min
% 3. Group data and apply the sampling function
% groupcounts converts categories into integer grouping variables (1, 2, 3...)
[G, ~] = findgroups(categorical(training_table.discretized_distance)); 

% 1. Create an array of row numbers (1 to total rows)
rowIndices = (1:height(training_table))';

% 2. Sample row indices per group (using the cell trick)
sampledRowsCell = splitapply(@(x) {datasample(x, min_cat, 'Replace', false)}, rowIndices, G);

% 3. Combine indices and extract the downsampled table
finalRows = vertcat(sampledRowsCell{:});
balanced_table = training_table(finalRows, :);

% Show the balanced result
disp(balanced_table);

%now get a neural network which will be used to train the current task
%10=num neurons per layer
%40 = num layers
% = number of classes
%4 = number of features in assembled data
layers_of_net = dynamically_create_layers_for_nn(size(balanced_table.unscaled_certainties,2),10,20,length(unique(balanced_table.discretized_distance)));

training_data = [balanced_table.unscaled_certainties,balanced_table.discretized_distance];
val_data = [val_table.unscaled_certainties,val_table.discretized_distance];
test_data = [testing_table.unscaled_certainties,testing_table.discretized_distance];


[trained_net] = train_a_net(training_data,val_data,layers_of_net,32);











end