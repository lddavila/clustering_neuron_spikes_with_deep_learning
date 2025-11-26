function [] = train_choose_better_with_thresh_prob(varargin)
current_script_file_path = mfilename('fullpath');
[current_script_dir,~,~] = fileparts(current_script_file_path);
cd(current_script_dir);

%first let's put all files on the path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
disp("Finished setting path")

%now we must get the config
config = spikesort_config();
parent_save_dir = config.parent_save_dir;
disp("Finished Loading Config")

%for AF's account broken profile
if contains(config.base_file_path,"afriedman")
    parpool('local_40', 40);
end

%create a directory where the results will be saved
dir_to_save_results_to = fullfile(parent_save_dir,"choose_better_with_thresh_probs");
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating directory")

if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_MASTER_TRAINING_BP_TABLE);
else
    blind_pass_table = varargin{1};
end
%blind_pass_table.og_index = (1:size(blind_pass_table,1)).';
disp("Finished loading blind pass table")

%set the random seed for repeatable results
rng("default")
disp("Finished setting seed")

%partition the blind pass table into test training data
paritioned_bp_table_array = partition_bp_tables(blind_pass_table,0);
training_data = paritioned_bp_table_array{1,1};
test_data = paritioned_bp_table_array{1,2};


%partition the training data into training and validation data
paritioned_training_data = partition_bp_tables(training_data,0);
training_data = paritioned_training_data{1,1};
val_data = paritioned_training_data{1,2};




%now navigate into the dir where we will save the results to
cd(dir_to_save_results_to);

%there's a practically infinit number of comarisons that can be made so we
%have to specify how many we'll realistically generate for training as
%computing the overlap feature can be very expensive
%0 = not groupable AKA do not represent the same underlying neuron
%1 = is groupable AKAK does represent the same underlying neuron
number_of_comparisons_per_class = 20000;

%get all possible comparisons of the training_set
all_training_comparisons = nchoosek(1:size(training_data,1),2);

%get all possible comparisons of the validation set
all_valdiation_comparisons = nchoosek(1:size(val_data,1),2);

%get the true class for all training comparisons
training_is_left_better = training_data{all_training_comparisons(:,1),"accuracy"}>training_data{all_training_comparisons(:,2),"accuracy"};

%get the true class for all validation comparisons
val_is_left_better = val_data{all_valdiation_comparisons(:,1),"accuracy"} >val_data{all_valdiation_comparisons(:,2),"accuracy"};

%randomly select number_of_comparisons_per_class from all comparisons in
%the training data
training_comparisons_with_class_1 = find(training_is_left_better);
training_is_same_idxs = training_comparisons_with_class_1(randperm(length(training_comparisons_with_class_1),number_of_comparisons_per_class));

training_comparisons_with_class_0 = find(~training_is_left_better);
training_is_not_same_idxs = training_comparisons_with_class_0(randperm(length(training_comparisons_with_class_0),number_of_comparisons_per_class));

%combine these idxs into single array
all_training_idxs = [training_is_not_same_idxs;training_is_same_idxs];

%randomly select number_of_comparisons_per_class from all comparisons in
%the validation data
val_comparisons_with_class_1 = find(val_is_left_better);
val_is_same_idxs = val_comparisons_with_class_1(randperm(length(val_comparisons_with_class_1),number_of_comparisons_per_class));

val_comparisons_with_class_0 = find(~val_is_left_better);
val_is_not_same_idxs = val_comparisons_with_class_0(randperm(length(val_comparisons_with_class_0),number_of_comparisons_per_class *2));

%combine all these idxs into single array
all_val_idxs = [val_is_not_same_idxs;val_is_same_idxs];

% now that we have the required idxs for both the training and validation
% data we can actually get the data that is required for training
%extract some required data for the computations we need to do
list_of_features_to_add = ["above_below"];
training_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,training_data,config);
training_assembled_data = training_assembled_data{1};
val_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,val_data,config);
val_assembled_data = val_assembled_data{1};

%now we can build the data that the neural network will use to
%train/validate
training_data = [training_assembled_data(all_training_comparisons(all_training_idxs),1),training_assembled_data(all_training_comparisons(all_training_idxs),2)];
validation_data = [val_assembled_data(all_valdiation_comparisons(all_val_idxs),1),val_assembled_data(all_valdiation_comparisons(all_val_idxs,2))];
%now we'll define a single neural network architecture which we'll hope can
%generalize
%10=num neurons per layer
%5 = num layers
%2 = number of classes
%4 = number of features in assembled data
layers_of_net = dynamically_create_layers_for_nn(size(training_data,2),10,5,2);


%now add the true classes to the training and validation data
training_data = [training_data,training_is_left_better(all_training_idxs)];
validation_data = [validation_data,val_is_left_better(all_val_idxs)];

%now we shuffle the rows of training and validation data
training_data = training_data(randperm(size(training_data,1),size(training_data,1)),:);
validation_data = validation_data(randperm(size(validation_data,1),size(validation_data,1)),:);

%now we can begin training
if ~isfile("choose_better_probs.mat")
    [accuracy,net] = test_nn_on_incremental_challenging(training_data,validation_data,layers_of_net,64);
    fprintf("Accuracy on training and validation data: %.2f",accuracy*100);

    par_save("choose_better_probs.mat",net);
else
    net = importdata("simplest_group_or_dont.mat");
end
end