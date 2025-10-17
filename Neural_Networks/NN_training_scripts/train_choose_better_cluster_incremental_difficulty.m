function [] = train_choose_better_cluster_incremental_difficulty()
%the goal of this function is to train the neural network on progressively
%harder and harder challenges

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

%first we must get the config
config = spikesort_config();
disp("Finished Loading Config")

%now we load the master training blind pass table which has various
%examples with various noise levels and accuracy
blind_pass_table = importdata(config.FP_TO_MASTER_TRAINING_BP_TABLE);
disp("Finished loading blind pass table")

%set the random seed for repeatable results
rng("default")
disp("Finished setting seed")

%now we'll extract some desired data from the blind_pass table which will
%be used for training 
feature_data = assemble_data_for_neural_net(["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","histogram 1","histogram 2", "histogram 3","histogram 4","size","grades 2"],blind_pass_table,config);
disp("Finished getting feature data")

%now we'll get all possible comparisons of 2 in the blind pass table
%luckily we will never suffer for lack of number of comparisons
all_comparisons = nchoosek(1:size(blind_pass_table,1),2);
disp("Finished getting all possible comparisons of 2")

%now for each comparison get a boolean vector which tells us if the "left"
%AKA 1st col of all_comparions
%has a higher accuracy
is_left_better = blind_pass_table{all_comparisons(:,1),"accuracy"} >= blind_pass_table{all_comparisons(:,2),"accuracy"};
disp("Finsihed getting is left better col")

%now we calculate the magnitude of the differences (Magnitude meaning abs
%difference)
mag_of_acc_differences = abs(blind_pass_table{all_comparisons(:,1),"accuracy"} -blind_pass_table{all_comparisons(:,2),"accuracy"});
disp("Finished calculating magnitude of differences")

%now we want to categorize the mag of accuracy differences
%they'll be increasing in magnitude by 5
list_of_magnitudes = 1:5:100;
cell_array_of_accuracy_mags = size(1:5:100,2);
for i=1:5:100
    cell_array_of_accuracy_mags{}
end
end