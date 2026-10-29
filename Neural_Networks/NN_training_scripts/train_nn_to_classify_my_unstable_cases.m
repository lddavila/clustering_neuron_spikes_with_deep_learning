function [] = train_nn_to_classify_my_unstable_cases(options)
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


save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"predict_unstable_class_2"));

blind_pass_table.og_row_num = (1:1:size(blind_pass_table,1)).';

% blind_pass_table.estimated_accuracies = ;
%we use the estimate produced by the ensemble as one of the features, in
%hopes that it will be a useful feature
blind_pass_table.feature_data = [certainty_curves,estimated_accuracies ./ 100];% to rescale between 0 & 1 to match rest of the data

%remove nans
blind_pass_table(isnan(estimated_accuracies),:) =[];
estimated_accuracies(isnan(estimated_accuracies)) =[];
distances_to_use = [5,10,15,20,25,30,35,40,45,50];


for i=1:length(distances_to_use)
    curr_dist = distances_to_use(i);
    blind_pass_table.true_class = abs(blind_pass_table.accuracy - estimated_accuracies) > curr_dist;
    [cell_array_of_parititioned_bp_tables] = partition_bp_tables(blind_pass_table,false,"split_into_test_train_val",true,"train_test_val_split",[0.7,.15,.15]);

    train_table = cell_array_of_parititioned_bp_tables{1};
    train_table = equalize_classes(train_table,"class_to_use","true_class");
    test_table = cell_array_of_parititioned_bp_tables{2};
    val_table = cell_array_of_parititioned_bp_tables{3};
    val_table= equalize_classes(val_table,"class_to_use","true_class");

    XValidation = val_table.feature_data;
    XTrain = train_table.feature_data;
    XTest = test_table.feature_data;

    accuracy_validation = categorical(val_table.true_class);
    accuracy_train = categorical(train_table.true_class);
    accuracy_test = categorical(test_table.true_class);

    layers = dynamically_create_layers_for_nn(size(XTrain,2),10,5,2);

    miniBatchSize = 128;


    % numIterationsPerEpoch = floor(numel(anglesTrain)/miniBatchSize);

    options = trainingOptions("adam", ...)
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

    net = trainnet(double(XTrain),accuracy_train,layers,"crossentropy",options);
    save(fullfile(save_dir,"trained_net_checkpoint.mat"),"net");




    scores = predict(net,XTest);
    [~,class_idx] = max(scores,[],2);

    % Your training targets were created using categorical(logical_values).
    class_names = string(categories(accuracy_train));
    class_values = double(class_names == "true");

    YPred = class_values(class_idx);
    YPred = YPred(:);

    % Read original logical labels directly; no categorical conversion.
    YTest = double(test_table.true_class(:));

    test_accuracy = mean(YPred == YTest);

    actual_outside = YTest == 1;
    pred_outside = YPred == 1;

    fprintf("Actual class 0: %d | Actual class 1: %d\n", ...
        sum(YTest == 0),sum(YTest == 1));

    f = figure;
    confusionchart(categorical(YTest),categorical(YPred));

    net_struct = struct;
    net_struct.layers = net;
    net_struct.accuracy = test_accuracy;
    net_struct.class_names = class_names;
    net_struct.distance_threshold = curr_dist;
    net_struct.num_training_instances = size(train_table,1);

    par_save(fullfile(save_dir,"the_net_for_within"+string(curr_dist)+"_acc_"+sprintf("%.2f",test_accuracy)+".mat"),net_struct);
    save_plots_in_all_formats(gcf,"the_net_for_within"+string(curr_dist)+"_acc_"+sprintf("%.2f",test_accuracy))
    close(f)


    actual_outside = categorical(YTest(:)) == categorical(1);
    pred_outside = categorical(YPred(:)) == categorical(1);

    tp = sum( actual_outside &  pred_outside);
    fn = sum( actual_outside & ~pred_outside);
    fp = sum(~actual_outside &  pred_outside);
    tn = sum(~actual_outside & ~pred_outside);

    % Undefined ratios return NaN rather than a misleading zero.
    outside_recall = NaN;
    outside_precision = NaN;
    within_recall = NaN;

    if tp + fn > 0
        outside_recall = tp / (tp + fn);
    end
    if tp + fp > 0
        outside_precision = tp / (tp + fp);
    end
    if tn + fp > 0
        within_recall = tn / (tn + fp);
    end

    balanced_accuracy = (outside_recall + within_recall) / 2;
    majority_baseline = max(mean(actual_outside),mean(~actual_outside));

    fprintf("Threshold: %g percentage points\n",curr_dist);
    fprintf("Outside prevalence: %.2f%%\n",100*mean(actual_outside));
    fprintf("Majority baseline:  %.2f%%\n",100*majority_baseline);
    fprintf("Balanced accuracy:  %.2f%%\n",100*balanced_accuracy);
    fprintf("Outside recall:     %.2f%%\n",100*outside_recall);
    fprintf("Outside precision:  %.2f%%\n",100*outside_precision);
    fprintf("Within recall:      %.2f%%\n",100*within_recall);
    fprintf("TP=%d FN=%d FP=%d TN=%d\n\n",tp,fn,fp,tn);
end
end