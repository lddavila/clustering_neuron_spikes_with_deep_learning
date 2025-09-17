function [] = train_nn_to_identify_same_neuron_via_image_of_spikes()
%add path
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%load the config
config = spikesort_config();
disp("Finished importing config")

%import the blind pass table
config.RECORDING_NAME = "sim_no_drift_first_300_seconds";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,config.RECORDING_NAME);
blind_pass_table = importdata(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table","blind_pass_table.mat"));
disp("Finished importing bp table")
disp("size of bp table");
disp(size(blind_pass_table));


%get all possible combinations of comparing 2 clusters
all_comparisons = nchoosek(1:size(blind_pass_table,1),2);
disp("finished getting all comparisons")
%determine which samples represent the same underlying unit
is_same_neuron = blind_pass_table{all_comparisons(:,1),"Max Overlap Unit"} == blind_pass_table{all_comparisons(:,2),"Max Overlap Unit"};
disp("finished getting is same neuron")
%now set how many training samples you want
num_training_samples = 100000;

%now from each class randomly sample num_training_samples/2
rng(0);
number_of_samples_per_class = round(num_training_samples);
is_same_neuron_indexes = find(is_same_neuron);
is_not_same_neuron_samples = find(~is_same_neuron);


random_groupable = all_comparisons(is_same_neuron_indexes(randperm(length(is_same_neuron_indexes),number_of_samples_per_class)),:);
random_non_groupable = all_comparisons(is_not_same_neuron_samples(randperm(length(is_not_same_neuron_samples),number_of_samples_per_class)),:);
all_training_values = [[random_non_groupable,zeros(size(random_non_groupable,1),1)];[random_groupable,zeros(size(random_groupable,1),1)+1]];
%shuffle the values
all_training_values = all_training_values(randperm(size(all_training_values,1),size(all_training_values,1)),:);
disp("finished shuffling values")
%now get all mean waveforms available for the left and right cluster
blind_pass_table_vars = string(blind_pass_table.Properties.VariableNames);
cols_of_mean_wfs = contains(blind_pass_table_vars,"mean_waveform");
mean_wf_cols = blind_pass_table_vars(cols_of_mean_wfs);
left_mean_wf_cell_array = cell(length(mean_wf_cols),1);
right_mean_wf_cell_array = cell(length(mean_wf_cols),1);
for i=1:length(mean_wf_cols)
    left_mean_wf_cell_array{i}= vertcat(blind_pass_table{all_training_values(:,1),mean_wf_cols(i)}{:});
    right_mean_wf_cell_array{i}=  vertcat(blind_pass_table{all_training_values(:,2),mean_wf_cols(i)}{:});
end

%now we can get the training images for the 2 wfs
dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"group_or_dont_based_on_wf"));
dir_to_save_images_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_results_to,"training_images"));
image_path =get_simple_wf_plots(left_mean_wf_cell_array,right_mean_wf_cell_array,dir_to_save_images_to);



%with the images created we can now train the neural networks
%now create an image data store based off of this data
imds = imageDatastore(image_path);
imds.Labels = categorical(all_training_values(:,3));

%now specify training and validation data
[imdsTrain,imdsValidation] = splitEachLabel(imds,0.75,"randomized");

%now get the class labels
%classNames = categories(imdsTrain.Labels);

%now we get the neural network which we'll use to train the identifcation
%inputSize = size(grayscale_image);
num_classes = 2;
input_size = [450,300,1];

%now specify training options
options = trainingOptions("sgdm", ...
    MaxEpochs=40, ...                      % fewer epochs; CNN learns faster
    MiniBatchSize=64, ...
    InitialLearnRate=1e-2, ...
    Momentum=0.9, ...
    ValidationData=imdsValidation, ...
    ValidationFrequency=30, ...
    ValidationPatience=5, ...              % early stopping on plateau
    Shuffle="every-epoch", ...
    Metrics="accuracy", ...
    Plots="training-progress", ...
    Verbose=true, ...
    ExecutionEnvironment="auto");          % use GPU if present
disp("Finished setting options")

blocks        = [2 3 4 5 6];       % how many conv blocks (2–3)
baseFilters_all   = [32 64];     % starting #filters (16 or 32)
fcUnitsGrid   = [64 128];    % size of the FC layer
disp("Finished setting the meta parameters")
parfor baseFilters = baseFilters_all
    for num_blocks = blocks
        for fcUnits = fcUnitsGrid
            layers = makeTinyCNN(input_size, num_classes, num_blocks, baseFilters, fcUnits);

            %now train
            net = trainnet(imdsTrain,layers,"crossentropy",options);

            %now get the accuracy of the net
            accuracy = testnet(net,imdsValidation,"accuracy");
            disp("Accuracy")
            disp(accuracy);

            par_save(fullfile(dir_to_save_results_to,sprintf("accuracy_%.2f_num_blocks_%i_fc_units_%i.mat",accuracy,num_blocks,fcUnits)),net);
        end
    end
end
end