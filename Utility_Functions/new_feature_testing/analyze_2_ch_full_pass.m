%% import the data
bp_2_ch = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\from_ls6\2_ch\blind_pass_table.mat");
new_cl_1 = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\from_ls6\2_ch\splitting_cluster_by_ampsplit_by_davies_split_by_amp\new_clusters.mat");
new_cl_2 = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\from_ls6\2_ch\splitting_cluster_by_ampsplit_by_amp_split_by_davies\new_clusters.mat");

%% get list of unique units in the blind pass table
counts_over_80 = groupcounts(bp_2_ch(bp_2_ch{:,"accuracy"}>80,:),"Max_Overlap_Unit");
unique_units_from_bp = counts_over_80.Max_Overlap_Unit;
%% get list of unique units over 80 not found in the blind pass from first method
new_cl_1_over_80 = groupcounts(new_cl_1(new_cl_1{:,"accuracy"} > 80,:),"Max_Overlap_Unit");


%% get list of unique units over 80 not found in the blind pass from 2nd method
new_cl_2_over_80 = groupcounts(new_cl_2(new_cl_2{:,"accuracy"} > 80,:),"Max_Overlap_Unit");

%% import a sample aligned file
sample_aligned = importdata("F:\cluster_data\full_set_10_600Neuron300SecondRecordingWithLevel10Noise_2_ch\prominance_and_peak_width_width_over_height\t1 aligned_to_peak_wf.mat");
disp(size(sample_aligned))

%% get the channels for the sample tetrode aligned
config = spikesort_config();
config.GT_FP = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\10_600Neuron300SecondRecordingWithLevel10Noise\ground_truth\ground_truth.mat";
config.fp_to_ch_to_units = "F:\cluster_data\full_set_10_600Neuron300SecondRecordingWithLevel10Noise_2_ch\DEBUG\table_of_best_rep_2.mat";
art_tetr_array = build_channel_configs(2,config);
channels = art_tetr_array(1,:);

%% get the table of best rep
table_of_best_rep = importdata("F:\cluster_data\full_set_10_600Neuron300SecondRecordingWithLevel10Noise_2_ch\DEBUG\table_of_best_rep_2.mat");

%% get the rows of table of best rep relevant to the sample tetrode
c1 = ismember(table_of_best_rep{:,"all_channels"},channels);
c2 = table_of_best_rep.detection_ratio_stage_1 > 80;
c3 = table_of_best_rep.all_multiplier_idxs==3;
c4 = table_of_best_rep.tetrode == "t1";
only_relevant = sortrows(table_of_best_rep(c1 & c2 & c3 & c4,:),"detection_ratio_stage_1","descend");

%% get the number of unique units in this set
unique_units = unique(only_relevant.unit);

%% get the peaks
peaks = get_peaks(sample_aligned,true);

%% import the spike windows that correspond to the unit
sw = importdata("F:\cluster_data\full_set_10_600Neuron300SecondRecordingWithLevel10Noise_2_ch\prominance_and_peak_width_width_over_height\t1 sorted_spike_windows_after_purges.mat");

%% import the latest stage 
stage_9 = importdata("F:\cluster_data\full_set_10_600Neuron300SecondRecordingWithLevel10Noise_2_ch\prominance_and_peak_width_width_over_height\stage_9.mat");

%% 
clc;
c1_1 = ismember(bp_2_ch{:,"Max_Overlap_Unit"},only_relevant.unit);
c1_2 = bp_2_ch{:,"Tetrode"}=="t1";
only_relevant_from_full_pass = bp_2_ch(c1_1 & c1_2,:);
sorted_full_pass = sortrows(only_relevant_from_full_pass(:,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy","tp","fp","fn"]),"accuracy","descend");
A =sorted_full_pass.Max_Overlap_Unit;

[~, ia, ~] = unique(A, 'stable');
disp(sorted_full_pass(ia,:));

%% plot the peaks
clc;
close all;
config.current_channels = channels;
config.mutated_sw = sw;
config.ground_truth_cell_array = importdata(config.GT_FP);
config.which_thresh = 3;
general_peak_plotting_function(peaks,config,'what_kind_of_data','peaks','color_by_unit','true','channels',{[channels]},'close_plot',false);
title("Z Score 3")

config.which_thresh = 4;
general_peak_plotting_function(peaks,config,'what_kind_of_data','peaks','color_by_unit','true','channels',{[channels]},'close_plot',false);
title("Z Score 4")

config.which_thresh = 5;
general_peak_plotting_function(peaks,config,'what_kind_of_data','peaks','color_by_unit','true','channels',{[channels]},'close_plot',false);
title("Z Score 5")

config.which_thresh = 6;
general_peak_plotting_function(peaks,config,'what_kind_of_data','peaks','color_by_unit','true','channels',{[channels]},'close_plot',false);
title("Z Score 6")


config.which_thresh = 7;
general_peak_plotting_function(peaks,config,'what_kind_of_data','peaks','color_by_unit','true','channels',{[channels]},'close_plot',false);
title("Z Score 7")

config.which_thresh = 8;
general_peak_plotting_function(peaks,config,'what_kind_of_data','peaks','color_by_unit','true','channels',{[channels]},'close_plot',false);
title("Z Score 8")

config.which_thresh = 9;
general_peak_plotting_function(peaks,config,'what_kind_of_data','peaks','color_by_unit','true','channels',{[channels]});
title("Z Score 9")






