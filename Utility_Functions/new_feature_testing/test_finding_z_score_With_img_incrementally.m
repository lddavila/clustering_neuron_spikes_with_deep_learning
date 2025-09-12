function [] = test_finding_z_score_With_img_incrementally()
%because the reward function for the q-learning agent proved ot be a little
%to complex to properly develop I'm going to try and use a simpler machine
%learning approach
%similar to before we'll use a neural network to try and identify which
%tetrodes at which z scores will produce a cluster with 90% accuracy when
%we look at all 2d views available

clc;


%set the increments that will be used for each tetrode
increments_to_try = 3:0.1:12;

% add the path
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

startup;
disp("Finished Setting Recording Name")

%override the default config file to point towards the recording we'll be
%using for these tests
config.GT_FP = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","ground_truth","ground_truth.mat");
config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data","sim_no_drift_first_300_seconds","recordings_by_channel");
disp("Finished Setting directories")

%get the scale factor
scale_factor = config.SCALE_FACTOR;

%get a list of what is already done
list_of_existing_files =struct2table(dir(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"**",".")));
rows_to_exclude = string(list_of_existing_files{:,"name"}) == "." | string(list_of_existing_files{:,"name"})=="..";
list_of_existing_files(rows_to_exclude,:) = [];
what_is_computed = fullfile(string(list_of_existing_files{:,"folder"}),string(list_of_existing_files{:,"name"}));
config.ALREADY_DONE_FILES = what_is_computed;


%override the config file so that it uses differnt z scores
%7.5 is the z score used by default as it is the midpoint between 3 and 12
config.DEFAULT_CLUSTERING_Z_SCORES = increments_to_try;

%create the z score directory
if ~ismember(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"z_score"),what_is_computed) %means that the z_score matrix is already computed and we will skip computing it again
    z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"z_score")); %not yet computed
else
    z_score_dir = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"z_score");
end
disp("Finished Creating Z Score Directory");

%create the directory for the template files
create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"Shape_Template_PNGs"));

%load the timestamps into memory
timestamps = importdata(config.TIMESTAMP_FP);
disp("Finished Importing timestamps for recording")

%get the ordered list of channels
ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);

%get the channel statistics
beginning_time = tic;
[channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,config.DIR_WITH_OG_CHANNEL_RECORDINGS,z_score_dir,scale_factor,config,what_is_computed); %will get the mean and std of every channel and calculate z_score for data set if not yet created
mean_and_std_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std"));
save(fullfile(mean_and_std_dir,"mean_and_std.mat"),"channel_wise_means","channel_wise_std");
end_time = toc(beginning_time);
fprintf("Finished Getting mean and std, it took %f seconds\n",end_time)

%find all spikes where the z score is at least the lower bound
spikes_per_channel_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"spikes_per_channel min_z_score "+string(increments_to_try(1))));
detect_spikes_ver_2(spikes_per_channel_dir,ordered_list_of_channels,config.DIR_WITH_OG_CHANNEL_RECORDINGS,z_score_dir,increments_to_try(1),scale_factor,config);

%now get the modified spike windows where the z score is at least the lower bound
spike_windows_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"spike_windows min_z_score " + string(increments_to_try(1)) + " num dps "+ string(config.NUM_DPTS_TO_SLICE)));
get_lowest_bound_spike_windows(ordered_list_of_channels,spikes_per_channel_dir,increments_to_try(1),config.NUM_DPTS_TO_SLICE,z_score_dir,spike_windows_dir,config)

%to get a training set we'll want to produce a bunch of simple jpegs that
%we can analyze
%assuming we have a full blind pass available we can try getting the
%cluster images from every tetrode
%unfortunately this will be costly
%a full blind has 285 tetrodes and if we increment them as I desire it'll
%be 91 *285, but luckily I have already implemented a much faster version
%of the core clustering algorithm so hopefully we can avoid a lot of the
%overhead

%we won't do any grading or merging or any such thing
%we'll exclusively get the images then run the clustering then compute
%accuracy

%first we'll worry about getting the images as that is much simpler
art_tetrode_array = config.ART_TETR_ARRAY;
channel_recordings_dir = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
num_dpts = config.NUM_DPTS_TO_SLICE;
scale_factor = config.SCALE_FACTOR;
dir_to_save_images_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"images"));

num_iterations = size(art_tetrode_array,1) * length(increments_to_try);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"getting_training_images.m")
cell_array_of_image_data = cell(size(art_tetrode_array,1),1);
if ~ismember(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"image_table.mat"),what_is_computed)
    parfor i=1:size(art_tetrode_array,1)
        sub_cell_array_of_image_data = cell(length(increments_to_try),1);
        %table_of_image_data = cell2table(cell(0,3),'VariableNames',["Tetrode","Z Score","image_path"]);
        channels = art_tetrode_array(i,:);
        counter =1;
        for z0=(increments_to_try)
            %get the cut spikes of the image
            save_name = fullfile(dir_to_save_images_to,sprintf("t%i %.2f",i,z0)+".png");
            sub_cell_array_of_image_data{counter} =table(i,z0,save_name,'VariableNames',["Tetrode","Z Score","image_path"]);
            %check to make sure the image doesn't already exist and if it does
            %we wont recreate it
            if ~ismember(save_name,what_is_computed)
                spikes_of_random_tetr =get_spike_slices(channels,spike_windows_dir,channel_recordings_dir,num_dpts,scale_factor,z0);
                if isempty(spikes_of_random_tetr)
                    continue;
                end
                %get the grayscale image of the spikes
                grayscale_image = produce_nth_dimensional_view(spikes_of_random_tetr,channels);
                %save the image
                par_save_as_jpeg(save_name,grayscale_image)
            end
            send(q,[]);
            counter = counter+1;
        end
        cell_array_of_image_data{i} = vertcat(sub_cell_array_of_image_data{:});
        
    end
    table_of_image_data = vertcat(cell_array_of_image_data{:});
    par_save(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"image_table.mat"),table_of_image_data);
else
    table_of_image_data = importdata(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"image_table.mat"));
end
disp("Finished creating images")

%now that the training images are created we can run the clustering using
%the modified clustering algorithm to classify each image as having at
%least 1 cluster that is at least 90% accurate
if ~ismember(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"table_of_image_accuracy_data.mat"),what_is_computed)
    num_iterations = size(art_tetrode_array,1) * length(increments_to_try);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    print_status_bar(num_iterations,"getting accuracy for each image.m")
    cell_array_of_image_accuracy_data = cell(size(art_tetrode_array,1),1);
    parpool("threads");   
    parfor i=1:size(art_tetrode_array,1)
        sub_cell_array_of_image_accuracy_data = cell(length(increments_to_try),1);
        channels = art_tetrode_array(i,:);

        for j=1:length(increments_to_try)
            z0= increments_to_try(j)
            temp_config = config;
            temp_config.DEFAULT_CLUSTERING_Z_SCORES = z0;
            [~,blind_pass_table] = modified_run_entire_clustering_algorithm_for_img_analysis(temp_config,timestamps,spike_windows_dir,channels,channel_wise_means,channel_wise_std,i);
            if ~isempty(blind_pass_table)
                max_accuracy = max([max(blind_pass_table{:,"accuracy"}),0]); %meant to return a 0 if there's no cluster with a max accuracy
            else
                max_accuracy = 0;
            end
            sub_cell_array_of_image_accuracy_data{j} =table(i,z0,max_accuracy,max_accuracy>90,'VariableNames',["Tetrode","Z Score","accuracy","accuracy_class"]);
            send(q,[]);
        end
        cell_array_of_image_accuracy_data{i} = vertcat(sub_cell_array_of_image_accuracy_data{:});
       
    end
    table_of_image_accuracy_data = vertcat(cell_array_of_image_accuracy_data{:});
    par_save(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"table_of_image_accuracy_data.mat"),table_of_image_accuracy_data);
else
    table_of_image_accuracy_data =importdata(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"table_of_image_accuracy_data.mat")) ;
end
disp("Finished getting accuracy");
%now we'll combine the two tables in order to classify our training data

training_data = join(table_of_image_data,table_of_image_accuracy_data,"Keys",["Tetrode","Z Score"]);

% we want to equalize the classes
% we do this because regardless of the proportions of the training dataset
% we want to ensure that the neural network gives every image the same
% chance of being identified as a valid class 
over_n_groupcounts = groupcounts(training_data,"accuracy_class");
min_num_samples = min(over_n_groupcounts{:,"GroupCount"});
indexes_of_positives = find(training_data{:,"accuracy_class"}==1);
indexes_of_negatives = find(training_data{:,"accuracy_class"}==0);

s = RandStream('mlfg6331_64'); 
random_positives= datasample(s,indexes_of_positives,min_num_samples,'Replace',false);
random_negatives = datasample(s,indexes_of_negatives,min_num_samples,'Replace',false);

equalized_classes = training_data([random_positives;random_negatives],:);
shuffled_data = equalized_classes(randperm(size(equalized_classes,1),size(equalized_classes,1)),:);

%now create an image data store based off of this data
imds = imageDatastore(shuffled_data.image_path);
imds.Labels = categorical(shuffled_data.accuracy_class);

%now specify training and validation data
numTrainFiles = round(size(shuffled_data,1) *0.75);
[imdsTrain,imdsValidation] = splitEachLabel(imds,numTrainFiles,"randomized");

%now get the class labels
classNames = categories(imdsTrain.Labels);

%now we get the neural network which we'll use to train the identifcation
%inputSize = size(grayscale_image);
numClasses = 2;
input_size = [200,300,1];
layers = [
    imageInputLayer(input_size)
    convolution2dLayer(5,20)
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(numClasses)
    softmaxLayer];

%now specify training options
options = trainingOptions("sgdm", ...
    MaxEpochs=50, ...
    ValidationData=imdsValidation, ...
    ValidationFrequency=30, ...
    Plots="training-progress", ...
    Metrics="accuracy", ...
    Verbose=false);

%now train
net = trainnet(imdsTrain,layers,"crossentropy",options);

%now get the accuracy of the net
accuracy = testnet(net,imdsValidation,"accuracy");
disp("Accuracy")
disp(accuracy);
end


