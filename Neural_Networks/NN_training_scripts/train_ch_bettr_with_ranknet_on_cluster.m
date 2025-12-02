function [] = train_ch_bettr_with_ranknet_on_cluster(varargin)
% Train a Siamese RankNet-style model to choose the better cluster.
% Uses scalar score s(x) and P(x1 > x2) = sigmoid(s(x1) - s(x2)).

% --- Path & config ---
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
    fullfile(config.parent_save_dir,"ch_bttr_with_twin"));
disp("Finished creating save dir");

% --- Load blind pass table ---
if nargin < 1
    blind_pass_table = importdata(config.FP_TO_6_to_10);
else
    blind_pass_table = varargin{1};
end
disp("Finished loading blind pass table");

% Filter out MUA (accuracy < 1)
blind_pass_table(blind_pass_table{:,"accuracy"} < 1, :) = [];
disp("Finished filtering blind pass");

% --- Partition into train / val / test at unit level ---
partitioned_data = partition_bp_tables(blind_pass_table,0);
test_data    = partitioned_data{2};
training_data = partitioned_data{1};

partitioned_data = partition_bp_tables(training_data,0);
training_data = partitioned_data{1};
val_data      = partitioned_data{2};
disp("Finished partitioning training / val / test");

% --- Features ---
list_of_features_to_add = ["grades 2","valley_1","valley_2"];

training_features_array = assemble_data_for_neural_net(list_of_features_to_add,training_data,config);
training_features_array = cell2mat(training_features_array);

val_features_array = assemble_data_for_neural_net(list_of_features_to_add,val_data,config);
val_features_array = cell2mat(val_features_array);

test_features_array = assemble_data_for_neural_net(list_of_features_to_add,test_data,config);
test_features_array = cell2mat(test_features_array);

disp("Finished getting features");

% Normalize based on training data
col_min = min(training_features_array,[],1);
col_max = max(training_features_array,[],1);

training_features_array = rescale(training_features_array,0,1, ...
    "InputMax",col_max,"InputMin",col_min);
val_features_array = rescale(val_features_array,0,1, ...
    "InputMax",col_max,"InputMin",col_min);
test_features_array = rescale(test_features_array,0,1, ...
    "InputMax",col_max,"InputMin",col_min);

% --- Pairwise comparisons ---
% Debug: only use ~20% of rows to keep nchoosek small.
nTrain = round(size(training_features_array,1)/2);
nVal   = round(size(val_features_array,1)/2);
nTest  = round(size(test_features_array,1)/2);

training_all_comparisons = nchoosek(1:nTrain,2);
val_all_comparisons      = nchoosek(1:nVal,2);
test_all_comparisons     = nchoosek(1:nTest,2);

% True class: 1 if left cluster better, 0 otherwise.
train_true_class = training_data{training_all_comparisons(:,1),"accuracy"} > ...
    training_data{training_all_comparisons(:,2),"accuracy"};
val_true_class   = val_data{val_all_comparisons(:,1),"accuracy"} > ...
    val_data{val_all_comparisons(:,2),"accuracy"};
test_true_class  = test_data{test_all_comparisons(:,1),"accuracy"} > ...
    test_data{test_all_comparisons(:,2),"accuracy"};

% we'll also want to keep track of the magnitude of accuracy differences
%this is necessary because the very easy choices are simple for the neural
%network to make (large accuracy differrences are easy to identify)

%the goal is to find a general solution so we'll ensure that during
%training/validating/testing that there's an equal distribution of
%hard/easy cases hopefully preventing a misleading accuracy rate on test
%data
train_mag_differences = abs(training_data{training_all_comparisons(:,1),"accuracy"} - training_data{training_all_comparisons(:,2),"accuracy"});
val_mag_differences = abs(val_data{val_all_comparisons(:,1),"accuracy"} - val_data{val_all_comparisons(:,2),"accuracy"});
test_mag_differences = abs(test_data{test_all_comparisons(:,1),"accuracy"} - test_data{test_all_comparisons(:,2),"accuracy"});

%set some buckets of difficulty
difficulty_buckets = [0,1,5,10,20,30,40,50,60];

%add the difficulty category to all test/training/val comparisons
train_bucket = get_difficulty_buckets_array(train_mag_differences,difficulty_buckets);
val_buckets = get_difficulty_buckets_array(val_mag_differences,difficulty_buckets);
test_buckets = get_difficulty_buckets_array(test_mag_differences,difficulty_buckets);


%randomly sample the test/training/validation data to ensure that all
%difficulty classes are equally represented
[training_all_comparisons,train_true_class,~] = sample_data_by_difficulty_bucket(training_all_comparisons,train_true_class,train_bucket);
[val_all_comparisons,val_true_class,~] = sample_data_by_difficulty_bucket(val_all_comparisons,val_true_class,val_buckets);
%we equalize test data to ensure that accuracy is not improperly inflated
%from a large set of easy choices in the test data
[test_all_comparisons,test_true_class,~] = sample_data_by_difficulty_bucket(test_all_comparisons,test_true_class,test_buckets);



disp("Finished computing pairwise labels");

% --- Build RankNet Siamese tower ---
% Dynamically create a network that outputs a scalar score
inputDim = size(training_features_array,2);
layers_of_net = dynamically_create_layers_for_nn(inputDim,10,5,1);

% Remove final softmax layer if present
if isa(layers_of_net(end), 'nnet.cnn.layer.SoftmaxLayer')
    layers_of_net(end) = [];
end

net = dlnetwork(layers_of_net);

% --- Training hyperparameters ---
numIterations  = 100000;
miniBatchSize  = 180;
learningRate   = 1e-3;
gradDecay      = 0.9;
gradDecaySq    = 0.99;
executionEnvironment = "auto";

if canUseGPU
    gpu = gpuDevice;
    disp(gpu.Name + " GPU detected and available for training.")
end

trainLosses = zeros(numIterations,1,'single');
valLosses   = zeros(numIterations,1,'single');

trailingAvgSubnet  = [];
trailingAvgSqSubnet = [];

% --- Build a fixed validation batch (for consistent val loss) ---
[valX1, valX2, valLabels] = getTwinBatch( ...
    val_all_comparisons, miniBatchSize, val_true_class, val_features_array);

valX1     = dlarray(single(valX1),"CB");
valX2     = dlarray(single(valX2),"CB");
valLabels = dlarray(single(valLabels),"CB");  % 1×B, 0/1

if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
    valX1     = gpuArray(valX1);
    valX2     = gpuArray(valX2);
    valLabels = gpuArray(valLabels);
end

% --- Training loop ---
for iteration = 1:numIterations

    % ---- training minibatch ----
    [X1,X2,pairLabels] = getTwinBatch( ...
        training_all_comparisons, miniBatchSize, train_true_class, training_features_array);

    X1 = dlarray(single(X1),"CB");
    X2 = dlarray(single(X2),"CB");
    pairLabels = dlarray(single(pairLabels),"CB");  % 1×B

    if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
        X1 = gpuArray(X1);
        X2 = gpuArray(X2);
        pairLabels = gpuArray(pairLabels);
    end

    % ---- loss + gradients ----
    [loss, gradientsNet] = dlfeval(@modelLoss, net, X1, X2, pairLabels);

    [net, trailingAvgSubnet, trailingAvgSqSubnet] = adamupdate( ...
        net, gradientsNet, trailingAvgSubnet, trailingAvgSqSubnet, ...
        iteration, learningRate, gradDecay, gradDecaySq);

    % ---- validation loss ----
    Yval = forwardTwin(net, valX1, valX2);  % [1 × B]
    epsVal = 1e-7;
    valLoss = -mean( ...
        valLabels .* log(Yval + epsVal) + ...
        (1 - valLabels) .* log(1 - Yval + epsVal), ...
        'all');

    % ---- log losses ----
    trainLosses(iteration) = gather(extractdata(loss));
    valLosses(iteration)   = gather(extractdata(valLoss));


    fprintf("iteration: %i/%i | train_loss: %.6f | val_loss: %.6f\n", ...
        iteration, numIterations, trainLosses(iteration), valLosses(iteration));
end

% --- Save metrics ---
iterations = (1:numIterations).';
metrics_tbl = table(iterations, trainLosses, valLosses, ...
    'VariableNames', {'Iteration','TrainLoss','ValLoss'});

writetable(metrics_tbl, fullfile(dir_to_save_results_to,"ranknet_training_metrics.csv"));
save(fullfile(dir_to_save_results_to,"ranknet_training_metrics.mat"), "metrics_tbl");

% --- Save network ---
net_struct = struct();
net_struct.net     = net;
net_struct.col_min = col_min;
net_struct.col_max = col_max;

par_save(fullfile(dir_to_save_results_to,"siamese_choose_better.mat"), net_struct);

% --- Evaluate on test pairs ---
accuracy = zeros(1,5);
accuracyBatchSize = miniBatchSize;

for k = 1:5
    [X1,X2,pairLabelsAcc] = getTwinBatch( ...
        test_all_comparisons, miniBatchSize, test_true_class, test_features_array);

    X1dl = dlarray(single(X1),"CB");
    X2dl = dlarray(single(X2),"CB");

    if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
        X1dl = gpuArray(X1dl);
        X2dl = gpuArray(X2dl);
    end

    Predictions = predictTwin(net, X1dl, X2dl);  % 1×B probabilities
    Predictions = gather(extractdata(Predictions));
    Predictions = round(Predictions);            % 0/1

    accuracy(k) = sum(Predictions == pairLabelsAcc) / accuracyBatchSize;
end

disp("Test accuracies over 5 mini-batches:");
disp(accuracy);
disp("Mean test accuracy:");
disp(mean(accuracy));

% --- Nested helper functions ---

    function Y = forwardTwin(netLocal, X1Local, X2Local)
        % X1, X2: [features × batch]
        s1 = forward(netLocal, X1Local);   % [1 × batch]
        s2 = forward(netLocal, X2Local);   % [1 × batch]
        Y  = sigmoid(s1 - s2);             % RankNet: P(X1 > X2)
    end

    function [loss, gradientsNet] = modelLoss(netLocal, X1Local, X2Local, pairLabelsLocal)
        % pairLabelsLocal: numeric or dlarray, 0/1, size [1 × B]
        s1 = forward(netLocal, X1Local);   % [1 × B]
        s2 = forward(netLocal, X2Local);   % [1 × B]
        probs = sigmoid(s1 - s2);          % [1 × B], P(X1 > X2)

        % Ensure labels are same type/device as probs
        if ~isa(pairLabelsLocal,'dlarray')
            pairLabelsLocal = dlarray(single(pairLabelsLocal),"CB");
        end
        if isa(probs,'gpuArray') && ~isaUnderlying(pairLabelsLocal,'gpuArray')
            pairLabelsLocal = gpuArray(pairLabelsLocal);
        end

        epsVal = 1e-7;
        loss = -mean( ...
            pairLabelsLocal .* log(probs + epsVal) + ...
            (1 - pairLabelsLocal) .* log(1 - probs + epsVal), ...
            'all');

        gradientsNet = dlgradient(loss, netLocal.Learnables);
    end

    function Y = predictTwin(netLocal, X1Local, X2Local)
        s1 = predict(netLocal, X1Local);
        s2 = predict(netLocal, X2Local);
        Y  = sigmoid(s1 - s2);
    end

    function [X1,X2,pair_labels] = getTwinBatch(all_combinations, mini_batch_size, true_combination_labels, features)
        % Sample a mini-batch of pairs with labels indicating whether
        % the LEFT element is better (1) or not (0).
        %
        % all_combinations: [N_pairs × 2] indices into rows of `features` & data tables
        % true_combination_labels: logical [N_pairs × 1], 1 if left > right
        % features: [N_items × N_features]

        pair_labels = zeros(1,mini_batch_size, 'single');
        X1 = zeros(size(features,2), mini_batch_size, 'single');
        X2 = zeros(size(features,2), mini_batch_size, 'single');

        % indexes where label == 0 or 1
        idx0 = find(~true_combination_labels);
        idx1 = find(true_combination_labels);

        for ii = 1:mini_batch_size
            choice = rand();

            if choice < 0.5
                % sample a "left not better" pair (label 0)
                random_index = idx0(randi(numel(idx0)));
                pair_labels(ii) = 0;
            else
                % sample a "left better" pair (label 1)
                random_index = idx1(randi(numel(idx1)));
                pair_labels(ii) = 1;
            end

            pair_idx_1 = all_combinations(random_index,1);
            pair_idx_2 = all_combinations(random_index,2);

            X1(:,ii) = single(features(pair_idx_1,:)).';
            X2(:,ii) = single(features(pair_idx_2,:)).';
        end
    end

end