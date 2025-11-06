%% use this script to compare images of the waveforms
new_level_6_bp_table = importdata("C:\Users\ldd77\OneDrive\Desktop\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\6_600Neuron300SecondRecordingWithLevel6Noise\blind_pass_table\blind_pass_table.mat");

%% get some examples 
config = spikesort_config();
only_rec_6 = new_level_6_bp_table;
only_unit_2_from_6 = only_rec_6(only_rec_6{:,"Max_Overlap_Unit"}==548 & only_rec_6{:,"accuracy"}>50,:);
only_unit_3_from_6 = only_rec_6(only_rec_6{:,"Max_Overlap_Unit"}==435 & only_rec_6{:,"accuracy"}>50,:);

%% compare some examples when the unit is the same
number_of_examples_to_test = 1;
all_comparisons = nchoosek(1:size(only_unit_2_from_6,1),2);
all_comparisons = all_comparisons(1:number_of_examples_to_test,:);
% all_comparisons = all_comparisons(randperm(size(all_comparisons,1),number_of_examples_to_test),:);
get_image_to_group_clusters(only_unit_2_from_6,all_comparisons,config);
%% compare some examples when the unit isn't the same
all_comp