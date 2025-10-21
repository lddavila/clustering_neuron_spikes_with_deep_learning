function [] = train_choose_better_cluster_incremental_difficulty(varargin)
%the goal of this function is to train the neural network on progressively
%harder and harder challenges

%ensure that you're on the correct fp while running the scipt
current_script_file_path = mfilename('fullpath');
[current_script_dir,~,~] = fileparts(current_script_file_path);
cd(current_script_dir);

%we know already that it can easily choose better with practically 100%
%accuracy when the accuracy differences are large

%we also know that they fail when the accuracy differences are closer
%together

%so hopefully multiple training phases with smaller and smaller accuracy
%decreases will improve overall training

%first let's put all files on the path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%now we must get the config
config = spikesort_config();
parent_save_dir = config.parent_save_dir;
disp("Finished Loading Config")

%create a directory where the results will be saved
dir_to_save_results_to = fullfile(parent_save_dir,"incremental_ch_bttr_nn");
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating directory")



%now we load the master training blind pass table which has various
%examples with various noise levels and accuracy
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_MASTER_TRAINING_BP_TABLE);
else
    blind_pass_table = varargin{1};
end
%set the random seed for repeatable results
rng("default")





%blind_pass_table.og_index = (1:size(blind_pass_table,1)).';
disp("Finished loading blind pass table")


disp("Finished setting seed")

%now we'll extract some desired data from the blind_pass table which will be used for training 
list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","histogram 1","histogram 2", "histogram 3","histogram 4","size","grades 2"];
all_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);

disp("Finished getting feature data")


%to avoid data leakage we will partition out a subset of the assembled data
%so that the validation occurs on never before seen data
random_indexes_for_validation = randperm(size(blind_pass_table,1),floor(size(blind_pass_table,1) * 0.3));
assembled_data_validation_subset = cellfun(@(x) x(random_indexes_for_validation,:),all_assembled_data,'UniformOutput',false);
validation_blind_pass_table = blind_pass_table(random_indexes_for_validation,:);


%remove the validation rows from the blind pass table
blind_pass_table(random_indexes_for_validation,:) = [];

%also remove those same rows from the data that will be used for training
new_data = cellfun(@(x) x(setdiff(1:size(x,1), random_indexes_for_validation), :), all_assembled_data, 'UniformOutput', false);

%go through new_data and normalize the values
%save the min/max of each dataset to 
cell_array_of_col_min = cell(length(all_assembled_data),1);
cell_array_of_col_max = cell(length(all_assembled_data),1);
for i=1:length(new_data)
    cell_array_of_col_max{i} = max(new_data{i},[],1);
    cell_array_of_col_min{i} = min(new_data{i},[],1);
    new_data{i} = normalize(new_data{i},'range');
end

%now normalize validation data based on the new data min/max
for i=1:length(assembled_data_validation_subset)
    col_max = cell_array_of_col_max{i};
    col_min = cell_array_of_col_min{i};
    range = col_max - col_min;
    range(range==0) = eps;
    assembled_data_validation_subset{i} = (assembled_data_validation_subset{i} - col_min) ./ range;
end


%now we'll get all possible comparisons of 2 in what remains of the
%blind_pass_table
all_comparisons_for_training = nchoosek(1:size(new_data{1},1),2);
%shuffle these rows to minimize repeats of clusters at the to
randomized_comparison_idxs = randperm(size(all_comparisons_for_training,1));
all_comparisons_for_training= all_comparisons_for_training(randomized_comparison_idxs,:);

%similarly we'll get all the possible_comparisons for the subset of
%comparisons taken out from the blind_pass_table
all_comparisons_for_validation = nchoosek(1:size(assembled_data_validation_subset{1},1),2);
randomized_comparison_idxs = randperm(size(all_comparisons_for_validation,1));
all_comparisons_for_validation = all_comparisons_for_validation(randomized_comparison_idxs,:);
disp("Finished getting all possible comparisons of 2")

%now for each comparison get a boolean vector which tells us if the "left"
%AKA 1st col of all_comparions
%has a higher accuracy
is_left_better_col_for_training = blind_pass_table{all_comparisons_for_training(:,1),"accuracy"} >= blind_pass_table{all_comparisons_for_training(:,2),"accuracy"};
is_left_better_col_for_val = validation_blind_pass_table{all_comparisons_for_validation(:,1),"accuracy"} >= validation_blind_pass_table{all_comparisons_for_validation(:,2),"accuracy"};

%now we calculate the magnitude of the differences (Magnitude meaning abs difference)
mag_of_acc_differences_for_training = abs(blind_pass_table{all_comparisons_for_training(:,1),"accuracy"} -blind_pass_table{all_comparisons_for_training(:,2),"accuracy"});
mag_of_acc_differences_for_validation = abs(validation_blind_pass_table{all_comparisons_for_validation(:,1),"accuracy"} -validation_blind_pass_table{all_comparisons_for_validation(:,2),"accuracy"});
disp("Finished calculating magnitude of differences")

%now we want to categorize the mag of accuracy differences
%they'll be decreasing the magnitude of difference by 5 for every training
%set
list_of_magnitudes = 100:-5:1;
cell_array_of_accuracy_magnitudes_for_training = cell(size(list_of_magnitudes,2),1);
cell_array_of_accuracy_magnitudes_for_validation = cell(size(list_of_magnitudes,2),1);
for i=1:length(list_of_magnitudes)-1
    c1 = mag_of_acc_differences_for_training > list_of_magnitudes(i+1);
    c2 = mag_of_acc_differences_for_training <= list_of_magnitudes(i);

    c3 = mag_of_acc_differences_for_validation > list_of_magnitudes(i+1);
    c4 = mag_of_acc_differences_for_validation <= list_of_magnitudes(i);

    [cell_array_of_accuracy_magnitudes_for_training{i},~] = find(c1 & c2);
    [cell_array_of_accuracy_magnitudes_for_validation{i},~] = find(c3 & c4);
end


%set some hyperparameters for the series of trainings we will be doing
number_of_layers = 1:12;
filter_sizes = 5:5:30;

permutations_table = get_table_of_all_permutations_for_nn_training(["num_layers", ...
    "filter_sizes"], ...
    number_of_layers,filter_sizes);


%now navigate into the dir to save results to
cd(dir_to_save_results_to);

%now we begin data assembly
disp("Beginning training set assembly");

%get a bunch of neural network with various architectures that will be
%trained below
cell_array_of_neural_networks = cell(size(permutations_table,1),1);
cell_array_of_net_objects =cell(size(permutations_table,1),1) ;
array_of_continue_training = ones(size(permutations_table,1),1);
array_of_accuracy = zeros(size(permutations_table,1),length(cell_array_of_accuracy_magnitudes_for_training));
for i=1:size(permutations_table,1)
    %here 2 is not a "magic number" but reflects the is left/right better
    %where 0 indicates left is not better and 1 indicates the left cluster
    %is better (where better means has a higher accuracy)
    %4438 relates to the number of features expected for each training
    cell_array_of_neural_networks{i} = dynamically_create_layers_for_nn(4438,permutations_table{i,"filter_sizes"},permutations_table{i,"num_layers"},2);
end

%this first for loop is used to navigate through the levels of difficulty
%it starts with the easiest (located at the beginning of the cell_array_of_accuracy_magnitudes) and
%navigates to progressively harder difficulties (found at the end of cell_array_of_accuracy_magnitudes)
final_validation_data = [];
for difficulty_level=1:length(cell_array_of_accuracy_magnitudes_for_training)
    if isempty(cell_array_of_accuracy_magnitudes_for_training{difficulty_level})
        continue;
    end
    
    %as long as cell_array_of_accuracy_magnitudes{difficulty_level} is not
    %empty then we can proceed to try and train

    % for now I'll just assume we want to use ALL available features
    % if this proves to be insufficient than we'll worry about permutations
    % of features later

    indexes_to_use_for_training = cell_array_of_accuracy_magnitudes_for_training{difficulty_level};
    indexes_to_use_for_training = indexes_to_use_for_training(1:min([10000,length(indexes_to_use_for_training)])); %throttle # of comparisons

    indexes_to_use_for_validation = cell_array_of_accuracy_magnitudes_for_validation{difficulty_level};
    indexes_to_use_for_validation = indexes_to_use_for_validation(1:min([10000,length(indexes_to_use_for_validation)])); %throttle # of comparisons

    %the training data will be assembled in the same order that it appears in assembled data
    left_clust_data_training = cellfun(@(x) x(all_comparisons_for_training(indexes_to_use_for_training,1),:),new_data,'UniformOutput',false);
    left_clust_data_training = cell2mat(left_clust_data_training);
    right_clust_data_training= cellfun(@(x) x(all_comparisons_for_training(indexes_to_use_for_training,2),:),new_data,'UniformOutput',false);
    right_clust_data_training = cell2mat(right_clust_data_training);

    %now we assemble the validation data in the same way
    left_clust_data_validation= cellfun(@(x) x(all_comparisons_for_validation(indexes_to_use_for_validation,1),:),assembled_data_validation_subset,'UniformOutput',false);
    left_clust_data_validation = cell2mat(left_clust_data_validation);
    right_clust_data_validation= cellfun(@(x) x(all_comparisons_for_validation(indexes_to_use_for_validation,2),:),assembled_data_validation_subset,'UniformOutput',false);
    right_clust_data_validation = cell2mat(right_clust_data_validation);

    %with the data we now have to ensure that left is better and left is
    %not better has an equal probability of occuring
    %we do this to ensure there's no probability bias
    training_data = equalize_classes([left_clust_data_training,right_clust_data_training,is_left_better_col_for_training(indexes_to_use_for_training)]);
    validation_data = equalize_classes([left_clust_data_validation,right_clust_data_validation,is_left_better_col_for_val(indexes_to_use_for_validation)]);
    
    %remove any rows from training/validation data that produce nans
    training_data = rmmissing(training_data);
    validation_data = rmmissing(validation_data);

    %we want to put asside about 1000 datapoints from this difficulty level
    %to validate all fully trained neural networks on a mixed dataset of
    %various difficulty levels
    number_of_samples_to_extract = 500;

    list_of_all_left_is_better_idxs = find(validation_data(:,end)==1);
    first_n_left_is_better = list_of_all_left_is_better_idxs(1:number_of_samples_to_extract);

    list_of_all_right_is_better_idxs = find(validation_data(:,end)==0);
    first_n_right_is_better = list_of_all_right_is_better_idxs(1:number_of_samples_to_extract);

    final_validation_data = [final_validation_data;validation_data(first_n_right_is_better,:);validation_data(first_n_left_is_better,:)];

    %now remove those examples from training data to ensure no data leakage
    validation_data([first_n_left_is_better,first_n_right_is_better],:) = [];


  

    %now with all this assembled we can actually begin training
    disp("Beginning training on difficulty_level:"+string(difficulty_level))
   
     for i=1:5:size(permutations_table,1)
         if ~array_of_continue_training(i)
             continue;
         end
        %unlike previous models we perform multiple training phases
        fprintf("Training architecture %i on training set with level %i difficulty\n",i,difficulty_level)
        [accuracy,net] = test_nn_on_incremental_challenging(training_data,validation_data,cell_array_of_neural_networks{i},128);
        fprintf("Achieved %.2f accuracy on validation/testing data",accuracy)
        %if accuracy is less than 60% then we won't continue training
        %this will hopefully ensure we speed up training
        if accuracy < .6
            array_of_continue_training(i) = 0;
            array_of_accuracy(i,difficulty_level) = accuracy;
            cell_array_of_neural_networks{i} = [];
        else
            cell_array_of_neural_networks{i} = net.Layers;
            cell_array_of_net_objects{i} = net;
        end
     end
     clear("training_data")
   
    
    
end

%finally we can see how well the neural networks actually work on our
%validation data
all_final_accuracies = zeros(length(cell_array_of_neural_networks),1);
for i=1:length(cell_array_of_neural_networks)
    if isempty(cell_array_of_neural_networks{i})
        continue;
    end
    scores = predict(cell_array_of_net_objects{i},final_validation_data(:,1:end-1));
    [~,YPred] = max(scores,[],2);
    YPred = YPred-1;

    YTest = final_validation_data(:,end);
    all_final_accuracies(i) = sum(YPred== YTest)/numel(YTest);
end
disp(all_final_accuracies);
par_save("all_neural_nets.mat",cell_array_of_net_objects);
par_save("all_final_accuracies.mat",all_final_accuracies)
par_save("validatation_data.mat",validation_data)
end