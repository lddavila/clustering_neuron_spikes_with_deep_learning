function [] = train_regression_nn_to_predict_acc_based_on_certainty_curve(options)
arguments
    options.blind_pass_table = [];
    options.unscaled_certainties = [];
    options.estimated_accuracies = [];
end

if isempty(options.blind_pass_table)
else
    blind_pass_table = options.blind_pass_table;
end

if isempty(options.unscaled_certainties)
else
    certainty_curves = options.unscaled_certainties;
end

if isempty(options.estimated_accuracies)
else
    estimated_accuracies = options.estimated_accuracies;
end

home_dir = cd("..");
cd("..");

addpath(genpath(fullfile(pwd,"Neural_Networks/"))); 
addpath(genpath(fullfile(pwd,"Grading_scripts")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Utility_Functions")));


config = spikesort_config();


cd(home_dir);


save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"regression_acc_pred_based_on_curve"));

blind_pass_table.og_row_num = (1:1:size(blind_pass_table,1)).';
% blind_pass_table.estimated_accuracies = ;
%we use the estimate produced by the ensemble as one of the features, in
%hopes that it will be a useful feature
blind_pass_table.feature_data = [certainty_curves,estimated_accuracies ./ 100];% to rescale between 0 & 1 to match rest of the data

[cell_array_of_parititioned_bp_tables] = partition_bp_tables(blind_pass_table,false,"split_into_test_train_val",true,"train_test_val_split",[0.7,.15,.15]);

train_table = cell_array_of_parititioned_bp_tables{1};
test_table = cell_array_of_parititioned_bp_tables{2};
val_table = cell_array_of_parititioned_bp_tables{3};

XValidation = val_table.feature_data;
XTrain = train_table.feature_data;
XTest = test_table.feature_data;

accuracy_validation = val_table.accuracy;
accuracy_train = train_table.accuracy;
accuracy_test = test_table.accuracy;


layers = [
    featureInputLayer(size(XTrain,2))

    fullyConnectedLayer(64)
    batchNormalizationLayer
    reluLayer

    fullyConnectedLayer(32)
    batchNormalizationLayer
    reluLayer

    fullyConnectedLayer(1)
]; %here 1 is because we expect 1 prediction for accuracy;

miniBatchSize = 128;


% numIterationsPerEpoch = floor(numel(anglesTrain)/miniBatchSize);

options = trainingOptions("sgdm", ...
    MiniBatchSize=miniBatchSize, ...
    InitialLearnRate=1e-3, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.1, ...
    LearnRateDropPeriod=20, ...
    Shuffle="every-epoch", ...
    ValidationData={XValidation,accuracy_validation}, ...
    ValidationFrequency=15, ...
    Plots="training-progress", ...
    MaxEpochs=15, ...
    Verbose=false);

net = trainnet(XTrain,accuracy_train,layers,"mse",options);
save(fullfile(save_dir,"trained_net_checkpoint.mat"),"net");

% Predict: transpose observations-by-features to features-by-observations.
dlXTest = dlarray(single(XTest.'),"CB");
dlYTest = predict(net,dlXTest);

YTest = double(gather(extractdata(dlYTest)));
YTest = YTest(:);
accuracy_test = double(accuracy_test(:));

rmse = sqrt(mean((YTest - accuracy_test).^2));
fprintf("Test RMSE: %.3f percentage points\n",rmse);

figure
scatter(YTest,accuracy_test,"+")
xlabel("Prediction")
ylabel("Target")

hold on
plot([-60 60], [-60 60],"r--")

net_struct = struct;
net_struct.layers = net;
net_struct.rmse = rmse;

par_save(fullfile(save_dir,"the_net.mat"),net_struct);
end