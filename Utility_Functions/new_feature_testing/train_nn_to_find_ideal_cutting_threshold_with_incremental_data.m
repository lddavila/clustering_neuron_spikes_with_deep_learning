function [] = train_nn_to_find_ideal_cutting_threshold_with_incremental_data()
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%set the seed for reproducability
rng(0,'twister');

% get a default config file
config = spikesort_config();

%override the default config file to use a different save directory
config.RECORDING_NAME = "img_threshold_finding_incremental";
config.BLIND_PASS_DIR_PRECOMPUTED = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"img_threshold_finding_incremental"));
disp("Finished Setting Recording Name")



%override the default config file to point towards the recording we'll be
%using for these tests
config.GT_FP = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","ground_truth","ground_truth.mat");
config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","recordings_by_channel");
disp("Finished Setting directories")

%get the scale factor
scale_factor = config.SCALE_FACTOR;


fp_to_img_table = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"image_table.mat");
fp_to_accuracy_table = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"table_of_image_accuracy_data.mat");

table_of_image_data = importdata(fp_to_img_table);
table_of_image_accuracy_data = importdata(fp_to_accuracy_table);
image_path = repelem("",size(table_of_image_accuracy_data,1),1);
num_iterations = size(table_of_image_accuracy_data,1);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"getting fp for each image.m")
for i=1:size(table_of_image_accuracy_data,1)
    current_z_score = table_of_image_accuracy_data{i,"Z Score"};
    current_tetrode = str2double(strrep(table_of_image_accuracy_data{i,"Tetrode"},"t",""));
    path = table_of_image_data{table_of_image_data{:,"Z Score"} == current_z_score & table_of_image_data{:,"Tetrode"}==current_tetrode,"image_path"};
    if ~isempty(path)
        image_path(i) = path;
    end
    send(q,[]);
end
table_of_image_accuracy_data.("image_path") = image_path;
training_data = table_of_image_accuracy_data;
training_data(training_data{:,"image_path"}=="",:) = [];
training_data.og_idx = (1:size(training_data,1)).';

all_possible_accuracies = [40, 50, 60, 70, 80, 90];
blocks        = [2 3];       % how many conv blocks (2–3)
baseFilters_all   = [16 32];     % starting #filters (16 or 32)
fcUnitsGrid   = [64 128];    % size of the FC layer
disp("Finished setting the meta parameters")



for m=1:length(all_possible_accuracies)
    min_accuracy = all_possible_accuracies(m);
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"nets_for_incremental_img_threshold_min_acc_+"+string(min_accuracy)));
    accuracy_class = training_data{:,"accuracy"}>=min_accuracy;
    accuracy_class_data = table(accuracy_class);
    % training_data.accuracy_class = accuracy_class;
    % we want to equalize the classes
    % we do this because regardless of the proportions of the training dataset
    % we want to ensure that the neural network gives every image the same
    % chance of being identified as a valid class
    over_n_groupcounts = groupcounts(accuracy_class_data,"accuracy_class");
    min_num_samples = min(over_n_groupcounts{:,"GroupCount"});
    indexes_of_positives = find(accuracy_class_data{:,"accuracy_class"}==1);
    indexes_of_negatives = find(accuracy_class_data{:,"accuracy_class"}==0);

    s = RandStream('mlfg6331_64');
    random_positives= datasample(s,indexes_of_positives,min_num_samples,'Replace',false);
    random_negatives = datasample(s,indexes_of_negatives,min_num_samples,'Replace',false);

    equalized_classes = training_data([random_positives;random_negatives],:);
    shuffled_data = equalized_classes(randperm(size(equalized_classes,1),size(equalized_classes,1)),:);

    %now create an image data store based off of this data
    imds = imageDatastore(shuffled_data.image_path);
    imds.Labels = categorical(accuracy_class{shuffled_data.og_idx});

    %now specify training and validation data
    [imdsTrain,imdsValidation] = splitEachLabel(imds,0.75,"randomized");

    %now get the class labels
    %classNames = categories(imdsTrain.Labels);

    %now we get the neural network which we'll use to train the identifcation
    %inputSize = size(grayscale_image);
    num_classes = 2;
    input_size = [200,300,1];

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


    for baseFilters = baseFilters_all
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

end