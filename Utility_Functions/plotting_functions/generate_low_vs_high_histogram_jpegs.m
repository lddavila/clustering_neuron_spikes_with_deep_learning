function [] = generate_low_vs_high_histogram_jpegs()
%add path
home_dir = cd("..");
addpath(genpath(pwd));
cd(home_dir);

%get blind pass table
config = spikesort_config();
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);

%filter down to only neurons
blind_pass_table = blind_pass_table(blind_pass_table{:,"is_neuron"}==1,:);

%get the blind

end