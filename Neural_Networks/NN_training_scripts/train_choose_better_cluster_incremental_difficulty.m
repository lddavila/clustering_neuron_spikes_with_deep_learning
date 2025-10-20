function [] = train_choose_better_cluster_incremental_difficulty(varargin)
%the goal of this function is to train the neural network on progressively
%harder and harder challenges

%ensure that you're on the correct fp while running the scipt
current_script_file_path = mfilename('fullpath');
[current_script_dir,~,~] = fileparts(current_script_file_path);
cd(current_script_dir);
%first start the parallel pool so we can access the # of available workers
 c = parcluster('local'); 
 num_workers = c.NumWorkers;

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
%blind_pass_table.og_index = (1:size(blind_pass_table,1)).';
disp("Finished loading blind pass table")

%set the random seed for repeatable results
rng("default")
disp("Finished setting seed")

%now we'll extract some desired data from the blind_pass table which will be used for training 
list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","histogram 1","histogram 2", "histogram 3","histogram 4","size","grades 2"];
assembled_data = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);
%we'll want to cycle through assembled data and normalize all of them to
%aid in training
for i=1:length(assembled_data)
    assembled_data{i} = normalize(assembled_data{i},'range');
end
disp("Finished getting feature data")

%now we'll get all possible comparisons of 2 in the blind pass table
%luckily we will never suffer for lack of number of comparisons
all_comparisons = nchoosek(1:size(blind_pass_table,1),2);
disp("Finished getting all possible comparisons of 2")

%now for each comparison get a boolean vector which tells us if the "left"
%AKA 1st col of all_comparions
%has a higher accuracy
is_left_better_col = blind_pass_table{all_comparisons(:,1),"accuracy"} >= blind_pass_table{all_comparisons(:,2),"accuracy"};
%disp("Finsihed getting is left better col")

%now we calculate the magnitude of the differences (Magnitude meaning abs
%difference)
mag_of_acc_differences = abs(blind_pass_table{all_comparisons(:,1),"accuracy"} -blind_pass_table{all_comparisons(:,2),"accuracy"});
disp("Finished calculating magnitude of differences")

%now we want to categorize the mag of accuracy differences
%they'll be increasing in magnitude by 10
list_of_magnitudes = 1:5:100;
cell_array_of_accuracy_magnitudes = cell(size(list_of_magnitudes,2),1);
for i=1:length(list_of_magnitudes)-1
    c1 = mag_of_acc_differences <= list_of_magnitudes(i+1)-1;
    c2 = mag_of_acc_differences > list_of_magnitudes(i)-1;

    %first we must get the indexes of the rows that fall within the     current
    %bin
    [cell_array_of_accuracy_magnitudes{i},~] = find(c1 & c2);
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
array_of_accuracy = zeros(size(permutations_table,1),length(cell_array_of_accuracy_magnitudes));
for i=1:size(permutations_table,1)
    %here 2 is not a "magic number" but reflects the is left/right better
    %where 0 indicates left is not better and 1 indicates the left cluster
    %is better (where better means has a higher accuracy)
    %4438 relates to the number of features expected for each training
    cell_array_of_neural_networks{i} = dynamically_create_layers_for_nn(4438,permutations_table{i,"filter_sizes"},permutations_table{i,"num_layers"},2);
end

%this first for loop is used to navigate through the levels of difficulty
%it starts with the easiest (located at the end of the cell_array_of_accuracy_magnitudes) and
%navigates to progressively harder difficulties (found at the beginning of
%cell_array_of_accuracy_magnitudes)
validation_data = [];
for difficulty_level=length(cell_array_of_accuracy_magnitudes):-1:1
    if isempty(cell_array_of_accuracy_magnitudes{difficulty_level})
        continue;
    end
    
    %as long as cell_array_of_accuracy_magnitudes{difficulty_level} is not
    %empty then we can proceed to try and train

    % for now I'll just assume we want to use ALL available features
    % if this proves to be insufficient than we'll worry about permutations
    % of features later

    indexes_to_use = cell_array_of_accuracy_magnitudes{difficulty_level};
    indexes_to_use = indexes_to_use(1:min([500000,length(indexes_to_use)])); %throttle # of comparisons

    %the training data will be assembled in the same order that it appears
    %in assembled data
    left_clust_data = cellfun(@(x) x(all_comparisons(indexes_to_use,1),:),assembled_data,'UniformOutput',false);
    left_clust_data = cell2mat(left_clust_data);
    right_clust_data = cellfun(@(x) x(all_comparisons(indexes_to_use,2),:),assembled_data,'UniformOutput',false);
    right_clust_data = cell2mat(right_clust_data);

    %with the data we now have to ensure that left is better and left is
    %not better has an equal probability of occuring
    %we do this to ensure there's no probability bias
    training_data = equalize_classes(array2table([left_clust_data,right_clust_data,is_left_better_col(indexes_to_use)]));

    %remove any rows from training data that produce nans
    training_data = rmmissing(training_data);

    %we want to put asside about 1000 datapoints from this difficulty level
    %to validate all fully trained neural networks on a mixed dataset of
    %various difficulty levels
    number_of_samples_to_extract = 500;

    list_of_all_left_is_better_idxs = find(training_data{:,end}==1);
    first_n_left_is_better = list_of_all_left_is_better_idxs(1:number_of_samples_to_extract);

    list_of_all_right_is_better_idxs = find(training_data{:,end}==0);
    first_n_right_is_better = list_of_all_right_is_better_idxs(1:number_of_samples_to_extract);

    validation_data = [validation_data;training_data(first_n_right_is_better,:);training_data(first_n_left_is_better,:)];

    %now remove those examples from training data to ensure no data leakage
    training_data([first_n_left_is_better,first_n_right_is_better],:) = [];


    training_data_parallel = parallel.pool.Constant(training_data);

    %now with all this assembled we can actually begin training
    disp("Beginning training on difficulty_level:"+string(difficulty_level))
     parfor i=1:size(permutations_table,1)
         if ~array_of_continue_training(i)
             continue;
         end
        %unlike previous models we perform multiple training phases
        [accuracy,net] = test_nn_on_incremental_challenging(training_data_parallel.Value,cell_array_of_neural_networks{i},128);
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
     clear("training_data_parallel");
    
    
end

%finally we can see how well the neural networks actually work on our
%validation data
all_final_accuracies = zeros(length(cell_array_of_neural_networks),1);
for i=1:length(cell_array_of_neural_networks)
    if isempty(cell_array_of_neural_networks{i})
        continue;
    end
    scores = predict(cell_array_of_net_objects{i},table2array(validation_data(:,1:end-1)));
    [~,YPred] = max(scores,[],2);
    YPred = YPred-1;

    YTest = validation_data(:,end);
    all_final_accuracies(i) = sum(categorical(YPred)== YTest)/numel(YTest);
end
disp(all_final_accuracies);
par_save("all_neural_nets.mat",cell_array_of_net_objects);
par_save("all_final_accuracies.mat",all_final_accuracies)
par_save("validatation_data.mat",validation_data)
end