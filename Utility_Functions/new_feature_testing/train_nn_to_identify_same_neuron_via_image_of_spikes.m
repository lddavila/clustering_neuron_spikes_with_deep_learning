function [] = train_nn_to_identify_same_neuron_via_image_of_spikes()
%add path
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%load the config
config = spikesort_config();

%import the blind pass table
config.RECORDING_NAME = "sim_no_drift_first_300_seconds";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,config.RECORDING_NAME);
blind_pass_table = importdata(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table","blind_pass_table.mat"));


%get all possible combinations of comparing 2 clusters
all_comparisons = nchoosek(1:size(blind_pass_table,1),2);

%determine which samples represent the same underlying unit
is_same_neuron = blind_pass_table{all_comparisons(:,1),"Max Overlap Unit"} == blind_pass_table{all_comparisons(:,2),"Max Overlap Unit"};

%now set how many training samples you want
num_training_samples = 100000;

%now from each class randomly sample num_training_samples/2

number_of_samples_per_class = round(num_training_samples);
is_same_neuron_indexes = find(is_same_neuron);
is_not_same_neuron_samples = find(~is_same_neuron);

end