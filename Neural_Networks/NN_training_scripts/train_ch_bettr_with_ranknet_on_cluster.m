function [] = train_ch_bettr_with_ranknet_on_cluster(varargin)
%this function aims to try and solve the choose better problem using
%ranknet algorithm which requires a siamese neural network
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
dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"ch_bttr_with_twin"));

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


%normalize all features based on trainining data
col_min = min(training_features_array,[],1);
col_max = max(training_features_array,[],1);

training_features_array = rescale(training_features_array,0,1,"InputMax",col_max,"InputMin",col_min);
val_features_array = rescale(val_features_array,0,1,"InputMax",col_max,"InputMin",col_min);
test_features_array = rescale(test_features_array,0,1,"InputMax",col_max,"InputMin",col_min);

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
% training_all_comparisons = nchoosek(1:size(training_features_array,1),2);
% val_all_comparisons = nchoosek(1:size(val_features_array,1),2);
% test_all_comparisons = nchoosek(1:size(test_features_array,1),2);

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


%get a neural network which we'll try to generalize
%now get a neural network which will be used to train the current task
%10=num neurons per layer
%5 = num layers
%2 = number of classes
%4 = number of features in assembled data
layers_of_net = dynamically_create_layers_for_nn(size(training_features_array,2),10,5,2);

net = dlnetwork(layers_of_net);

fcWeights = dlarray(0.01*randn(1,2));
fcBias = dlarray(0.01*randn(1,1));

fcParams = struct(...
    "FcWeights",fcWeights,...
    "FcBias",fcBias);

%because matlab doesn't have a method of training siamese networkd directly
%we'll have to define a custom loop

%specify some training options
numIterations = 10000;
miniBatchSize = 180;
%specify options for adam optimizer
learningRate = 1e-3;
gradDecay = 0.9;
gradDecaySq = 0.99;

executionEnvironment = "auto";

trailingAvgSubnet = [];
trailingAvgSqSubnet = [];
trailingAvgParams = [];
trailingAvgSqParams = [];

if canUseGPU
    gpu = gpuDevice;
    disp(gpu.Name + " GPU detected and available for training.")
end



% Loop over mini-batches.
[valX1, valX2, valLabels] = getTwinBatch( ...
    val_all_comparisons, miniBatchSize, val_true_class, val_features_array);

valX1 = dlarray(single(valX1),"CB");
valX2 = dlarray(single(valX2),"CB");
valLabels = dlarray(single(valLabels),"CB");

if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
    valX1 = gpuArray(valX1);
    valX2 = gpuArray(valX2);
    valLabels = gpuArray(valLabels);
end

trainLosses = zeros(numIterations,1,'single');
valLosses   = zeros(numIterations,1,'single');


for iteration = 1:numIterations

    % ---- training minibatch ----
    [X1,X2,pairLabels] = getTwinBatch( ...
        training_all_comparisons, miniBatchSize, train_true_class, training_features_array);

    X1 = dlarray(single(X1),"CB");
    X2 = dlarray(single(X2),"CB");
    pairLabels = dlarray(single(pairLabels),"CB");

    if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
        X1 = gpuArray(X1);
        X2 = gpuArray(X2);
        pairLabels = gpuArray(pairLabels);
    end

    % ---- loss + gradients ----
    [loss,gradientsSubnet,gradientsParams] = dlfeval(@modelLoss,net,fcParams,X1,X2,pairLabels);

    % update subnet + head
    [net,trailingAvgSubnet,trailingAvgSqSubnet] = adamupdate(net,gradientsSubnet, ...
        trailingAvgSubnet,trailingAvgSqSubnet,iteration,learningRate,gradDecay,gradDecaySq);

    [fcParams,trailingAvgParams,trailingAvgSqParams] = adamupdate(fcParams,gradientsParams, ...
        trailingAvgParams,trailingAvgSqParams,iteration,learningRate,gradDecay,gradDecaySq);

    % ---- validation loss ----
    Yval    = forwardTwin(net, fcParams, valX1, valX2);
    valLoss = crossentropy(Yval, valLabels);

    % ---- log losses ----
    trainLosses(iteration) = gather(extractdata(loss));
    valLosses(iteration)   = gather(extractdata(valLoss));

    fprintf("iteration: %i/%i| training_loss: %.8f | validation_loss: %.8f\n",iteration,numIterations,trainLosses(iteration),valLosses(iteration));
    % disp("Finished iteration: "+string(iteration)+"/"+string(numIterations))
end

% build output table
iterations = (1:numIterations).';
metrics_tbl = table(iterations, trainLosses, valLosses, ...
    'VariableNames', {'Iteration','TrainLoss','ValLoss'});

writetable(metrics_tbl, fullfile(dir_to_save_results_to,"ranknet_training_metrics.csv"));
save(fullfile(dir_to_save_results_to,"ranknet_training_metrics.mat"), "metrics_tbl");

net_struct = struct();
net_struct.net = net;
net_struct.col_min = col_min;
net_struct.col_max = col_max;
net_struct.fc_params = fcParams;

%save the net
par_save(fullfile(dir_to_save_results_to,"siamense_choose_better.mat"),net_struct)
accuracy = zeros(1,5);
accuracyBatchSize = miniBatchSize;

for k = 1:5
    % Extract mini-batch of image pairs and pair labels
    [X1,X2,pairLabelsAcc] = getTwinBatch( ...
        test_all_comparisons, miniBatchSize, test_true_class, test_features_array);

    % Convert mini-batch of data to dlarray. Specify the dimension labels
    % "SSCB" (spatial, spatial, channel, batch) for image data.
    X1 = dlarray(X1,"CB");
    X2 = dlarray(X2,"CB");

    % If using a GPU, then convert data to gpuArray.
    if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
        X1 = gpuArray(X1);
        X2 = gpuArray(X2);
    end

    % Evaluate predictions using trained network
    Predictions = predictTwin(net,fcParams,X1,X2);

    % Convert predictions to binary 0 or 1
    Predictions = gather(extractdata(Predictions));
    Predictions = round(Predictions);

    % Compute average accuracy for the minibatch
    accuracy(k) = sum(Predictions == pairLabelsAcc)/accuracyBatchSize;
end

disp("Accuracy or something idk")
disp(accuracy);

    function Y = forwardTwin(net,fcParams,X1,X2)
        % forwardTwin accepts the network and pair of cluster features, and
        % returns a prediction of the probability that of X1 being ranked higher
        % than X2

        % Pass the first set of features through the twin subnetwork
        Y1 = forward(net,X1);
        % Y1 = sigmoid(Y1);

        % Pass the second set of features through twin subnetwork
        Y2 = forward(net,X2);
        % Y2 = sigmoid(Y2);

        % Subtract the feature vectors
        Y = abs(Y1 - Y2);

        % Pass the result through a fullyconnect operation
        Y = fullyconnect(Y,fcParams.FcWeights,fcParams.FcBias);

        % Convert to probability between 0 and 1.
        Y = sigmoid(Y);

    end

    function [loss,gradientsSubnet,gradientsParams] = modelLoss(net,fcParams,X1,X2,pairLabels)

        % Pass the cluster feature pair through the network.
        Y = forwardTwin(net,fcParams,X1,X2);

        % Calculate binary cross-entropy loss.
        loss = crossentropy(Y,pairLabels,ClassificationMode="single-label");

        % Calculate gradients of the loss with respect to the network learnable
        % parameters.
        [gradientsSubnet,gradientsParams] = dlgradient(loss,net.Learnables,fcParams);

    end

    function Y = predictTwin(net,fcParams,X1,X2)
        % predictTwin accepts the network and pair of images, and returns a
        % prediction of the probability of X1 being a higher rank than X2.
        % Use predictTwin during prediction.

        % Pass the first set of features through the twin subnetwork.
        Y1 = predict(net,X1);
        % Y1 = sigmoid(Y1);

        % Pass the second set of features through the twin subnetwork.
        Y2 = predict(net,X2);
        % Y2 = sigmoid(Y2);

        % Subtract the feature vectors.
        Y = abs(Y1 - Y2);

        % Pass result through a fullyconnect operation.
        Y = fullyconnect(Y,fcParams.FcWeights,fcParams.FcBias);

        % Convert to probability between 0 and 1.
        Y = sigmoid(Y);

    end
    function [X1,X2,pair_labels] = getTwinBatch(all_combinations,mini_batch_size,true_combination_labels,features)
        pair_labels = zeros(1,mini_batch_size);
        X1 = zeros(size(features,2),mini_batch_size);
        X2 = zeros(size(features,2),mini_batch_size);

        %get all indexes where true_combination_labels ==0
        [indexes_of_0,~]= find(~true_combination_labels);
        %get all indexes where true_combination_labels ==1
        [indexes_of_1,~] = find(true_combination_labels);
        % Create batch examples where X1 has a higher/lower rank than X2
        for i = 1:mini_batch_size
            choice = rand(1);

            % Randomly select instances where X1 has a higher/lower rank than X2
            if choice < 0.5
                random_index_of_0 = randperm(length(indexes_of_0),1);
                pair_idx_1 = all_combinations(indexes_of_0(random_index_of_0),1);
                pair_idx_2 = all_combinations(indexes_of_0(random_index_of_0),2);
                
            else
                random_index_of_1 = randperm(length(indexes_of_1),1);
                pair_idx_1 = all_combinations(indexes_of_1(random_index_of_1),1);
                pair_idx_2 = all_combinations(indexes_of_1(random_index_of_1),2);
                pair_labels(i) = 1;
            end

            X1(:,i) = features(pair_idx_1,:).';
            X2(:,i) = features(pair_idx_2,:).';
        end
    end
end