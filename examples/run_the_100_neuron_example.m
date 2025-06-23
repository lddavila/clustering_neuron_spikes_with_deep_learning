%% STEP 1: Add Utility functions to your path
cd("Utility Functions\");
addpath(pwd);
cd("..");
cd("clustering-master\")
addpath(genpath(pwd));
cd("..")
%% step 2: Get all the recording directories 
clc
recording_dir= "D:\spike_gen_data\Recordings By Channel";
%list_of_recording_dir = pwd;
files_containing_recordings = dir(recording_dir);
dir_flags = [files_containing_recordings.isdir];
subfolders = files_containing_recordings(dir_flags);
subfolder_names = {subfolders(3:end).name};
disp(subfolder_names.')
%% run the blind pass with a various min_z_score (cut threshold) 
precomputed_dir = "D:\spike_gen_data\Recordings By Channel Precomputed";
dir_of_timestamps = "D:\spike_gen_data\Recordings By Channel Timestamps";
varying_z_scores = [3,4,5,6,7,8,9];
for i=1:1.5%length(subfolder_names)
    what_is_precomputed = [""];
    for j=1:length(varying_z_scores)
        close all;
        clc;
        scale_factor = -1;
        dir_with_channel_recordings = recording_dir + "\"+string(subfolder_names{i});
        min_z_score = varying_z_scores(j);
        min_threshold = 20;
        num_dps = 60;
        timestamps_dir = dir_of_timestamps+"\"+string(subfolder_names{i});
        create_z_score_matrix = 0;
        precomputed_dir_current = precomputed_dir +"\"+string(subfolder_names{i});
        
        %what_is_precomputed = [""];
        what_is_precomputed = ["mean_and_std","z_score","dictionaries min_z_score "+string(min_z_score)+" num_dps 60","spike_windows min_z_score "+string(min_z_score)+" num dps 60","spikes_per_channel min_z_score " + string(min_z_score)];
        
        what_is_precomputed = run_entire_clustering_algorithm_ver_2(scale_factor,dir_with_channel_recordings,min_z_score,num_dps,timestamps_dir,precomputed_dir_current,what_is_precomputed,min_threshold);
        what_is_precomputed = ["z_score","mean_and_std"];
    end
end
%% compute the grades for the nth pass
clc;
config = spikesort_config; %load the config file;
config = config.spikesort;
clc;
close all;
dir_with_data = "D:\spike_gen_data\Recordings By Channel Precomputed";
current_recording = "0_100Neuron300SecondRecordingWithLevel3Noise";
debug = 0;
varying_z_scores = [3,4,5,6,7,8,9];
for i=1:length(varying_z_scores)
dir_with_output = "D:\spike_gen_data\Recordings By Channel Precomputed\"+current_recording+"\initial_pass_results min z_score"+string(varying_z_scores(i));
dir_to_save_grades_to = "D:\spike_gen_data\Recordings By Channel Precomputed\"+current_recording+"\initial_pass min z_score "+string(varying_z_scores(i))+" grades";
dir_to_save_grades_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_grades_to);
list_of_tetrodes = strcat("t",string(1:285));
dir_with_timestamps_and_rvals = "D:\spike_gen_data\Recordings By Channel Precomputed\"+current_recording+"\initial_pass min z_score"+string(varying_z_scores(i));
name_of_grades = ["Tight","% Short ISI","Inc", "Temp Mat","Min Bhat","Skewness","TM Updated","Sym of Hist","Amp Category"];
relevant_grades = [2,3,4,8,9,28,29,30,31];
get_grades_for_nth_pass_of_clustering(dir_with_timestamps_and_rvals,dir_with_output,list_of_tetrodes,dir_to_save_grades_to,config,varying_z_scores(i),debug,relevant_grades,name_of_grades)
end
%% id the best
clc;
%close all;
dir_with_pre_computed = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise";
varying_z_scores = [4,5,6,7,8,9];
tetrodes_to_check = strcat("t",string(1:285));
min_overlap_percentage = 30;
debug = 0;
grades_that_matter = [2,31,30,32,8,28,29,33,34,9,35,36,37,38,40,41];
names_of_grades =["CV (2)","Amp. (31)","Hist. Sym. (30)","R-Wire Amp(32)","TM(8)","CL. Skew(28)","TM New()","Chance Of M.U.A(33)","Min B-Dist From M.U.A(34)","Min B-Dist To Neighbor(9)","TM Cluster Level(35)","TM Rep Wire Level(36)","Min Bhat Best Dim","Best Dim","SNR","burst ratio(41)"] ;
generic_dir_with_grades = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\initial_pass min z_score";
generic_dir_with_outputs = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\initial_pass_results min z_score";
dir_to_save_figs_to = "D:\OneDrive - The University of Texas at El Paso\Graded Clusters Z Score 4";
load_previous_attempt = true;
save_results = true;
time_delta = 0.0004;
refinement_pass = false;
dir_to_save_to = "Data From Blind Pass";
[best_appearences_of_cluster_from_blind_pass,timestamps_of_best_clusters_from_blind_pass,table_of_overlapping_clusters_from_blind_pass]= id_best_representation_of_clusters(varying_z_scores,tetrodes_to_check,min_overlap_percentage,debug,grades_that_matter,names_of_grades,generic_dir_with_grades,generic_dir_with_outputs,dir_to_save_figs_to,load_previous_attempt,save_results,time_delta,refinement_pass,dir_to_save_to);
%% now compare these best representations to ground truth to see how well they compare
clc;
%close all;
ground_truth_dir = "D:\spike_gen_data\Recording By Channel Ground Truth";
ground_truth_array = load_ground_truth_into_data(ground_truth_dir);
dir_of_timestamps = "D:\spike_gen_data\Recordings By Channel Timestamps\0_100Neuron300SecondRecordingWithLevel3Noise";
timestamps = importdata(dir_of_timestamps+"\timestamps.mat") ;

min_percentage_threshold = 1;
time_delta = 0.004;
debug =0;

table_of_accuracy_of_clusters_from_blind_pass = compare_timestamps_to_ground_truth_ver_3(ground_truth_array{1},timestamps_of_best_clusters_from_blind_pass,timestamps,time_delta,debug,best_appearences_of_cluster_from_blind_pass);

%% plot the grades in a heatmap
%grades_to_check = ["accuracy","overlap_with_unit","number_of_false_positives","number_of_true_positives","agreement_scores","recall_scores","precision_scores"];
%grades_to_check = ["overlap_with_unit","number_of_false_positives","number_of_true_positives"];
grades_to_check = ["overlap_with_unit"];
create_heatmaps_of_grades_in_accuracy_table(table_of_accuracy_of_clusters_from_blind_pass,grades_to_check,85);

%% plot some sets to see why their overlap and etc did not work
% clc;
% %close all;
% dir_of_precomputed = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise";
% grades_to_check = ["overlap_with_unit"];
% plot_the_configurations = true;
% time_delta = 0.0004;
plot_debugging_sets(dir_of_precomputed,table_of_accuracy_of_clusters,70,grades_to_check,plot_the_configurations,time_delta);
%% diagnose the existence of expected error
% find_auxilary_overlap_clusters(table_of_overlapping_clusters,["t136","138"],["Z_Score:9 Cluster 1","Z_Score:9 Cluster 1"],table_of_only_neurons)

%% run the reclustering, as of 01/18/2024 there default number of channels is 4
min_amp=0;
clc;
close all;
load_previous_attempt = false;
save_current_attempt= true;

dir_to_save_data_to = pwd+"\Second Pass Data\"+string(i)+" Channels";
version_name = "0_100Neuron300SecondRecordingWithLevel3Noise";
generic_dir_with_grades = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\initial_pass min z_score";
generic_dir_with_outputs = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\initial_pass_results min z_score";
precomputed_dir = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise";
min_improvment = .1;
number_of_channels_in_new_config = 3;
num_dps = 60;
load(precomputed_dir+"\mean_and_std\mean_and_std.mat",'channel_wise_means','channel_wise_std') %loads the previously found mean and std
dir_with_chan_recordings = "D:\spike_gen_data\Recordings By Channel\0_100Neuron300SecondRecordingWithLevel3Noise";
timestamps_dir = "D:\spike_gen_data\Recordings By Channel Timestamps\0_100Neuron300SecondRecordingWithLevel3Noise";
timestamps = importdata(timestamps_dir+"\timestamps.mat");
scale_factor = -1;
min_threshold = 20;
refined_pass = false;
parent_dir = "Reclustered Pass";
recluster_with_ideal_dimensions(table_of_overlapping_clusters_2,load_previous_attempt,save_current_attempt,dir_to_save_data_to,version_name,generic_dir_with_grades,generic_dir_with_outputs,precomputed_dir,min_improvment,number_of_channels_in_new_config,num_dps,dir_with_chan_recordings,timestamps,scale_factor,channel_wise_means,channel_wise_std,min_threshold,refined_pass,min_amp,parent_dir)

%% now compute the grades for this refined pass
clc;
config = spikesort_config;
config = config.spikesort;
close all;
dir_with_data = "D:\spike_gen_data\Recordings By Channel Precomputed";
current_recording = "0_100Neuron300SecondRecordingWithLevel3Noise";
debug = 0;
dir_with_output = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\TEST refinement_pass_results min amp 0 Top 4 Channels";
dir_to_save_grades_to = dir_with_output+" grades";
dir_to_save_grades_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_grades_to);
list_of_tetrodes = strcat("t",string(1:200));
dir_with_timestamps_and_rvals = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\TEST refinement_pass min amp 0 Top 4 Channels";
name_of_grades = ["Tight","% Short ISI","Inc", "Temp Mat","Min Bhat","Skewness","TM Updated","Sym of Hist","Amp Category"];
relevant_grades = [2,3,4,8,9,28,29,30,31];
get_grades_for_nth_pass_of_clustering(dir_with_timestamps_and_rvals,dir_with_output,list_of_tetrodes,dir_to_save_grades_to,config,0,debug,relevant_grades,name_of_grades)

%% now run regrading on this reclustered data set 
clc;
%close all;
dir_with_output = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\TEST refinement_pass_results min amp 0 Top 4 Channels";
dir_with_pre_computed = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise";
varying_z_scores = [0];
tetrodes_to_check = strcat("t",string(1:148));
min_overlap_percentage = 30;
debug = 0;
grades_that_matter = [2,31,30,32,8,28,29,33,34,9,35,36,37,38,40,41];
names_of_grades =["CV (2)","Amp. (31)","Hist. Sym. (30)","R-Wire Amp(32)","TM(8)","CL. Skew(28)","TM New()","Chance Of M.U.A(33)","Min B-Dist From M.U.A(34)","Min B-Dist To Neighbor(9)","TM Cluster Level(35)","TM Rep Wire Level(36)","Min Bhat Best Dim","Best Dim","SNR","burst ratio(41)"] ;
generic_dir_with_grades = dir_with_output +" grades";
generic_dir_with_outputs = dir_with_output;
dir_to_save_figs_to = "D:\OneDrive - The University of Texas at El Paso\Graded Clusters Z Score 4";
load_previous_attempt = false;
save_results = true;
time_delta = 0.0004;
refinement_pass = true;
dir_to_save_to = "Reclustered Pass";
[best_appearences_of_cluster_from_reclustered_pass,timestamps_of_best_clusters_from_reclustered_pass,table_of_overlapping_clusters_from_reclustered_pass]= id_best_representation_of_clusters(varying_z_scores,tetrodes_to_check,min_overlap_percentage,debug,grades_that_matter,names_of_grades,generic_dir_with_grades,generic_dir_with_outputs,dir_to_save_figs_to,load_previous_attempt,save_results,time_delta,refinement_pass,dir_to_save_to);

%% now check the reclustered & regraded pass for its overlap with the ground truth
clc;
ground_truth_dir = "D:\spike_gen_data\Recording By Channel Ground Truth";
ground_truth_array = load_ground_truth_into_data(ground_truth_dir);
dir_of_timestamps = "D:\spike_gen_data\Recordings By Channel Timestamps\0_100Neuron300SecondRecordingWithLevel3Noise";
timestamps = importdata(dir_of_timestamps+"\timestamps.mat") ;

min_percentage_threshold = 1;
time_delta = 0.004;
debug =0;

table_of_accuracy_of_clusters_for_reclustered_pass = compare_timestamps_to_ground_truth_ver_3(ground_truth_array{1},timestamps_of_best_clusters_from_reclustered_pass,timestamps,time_delta,debug,best_appearences_of_cluster_from_reclustered_pass);

%% now compare the reclustered, regraded, and accuracies from the blind pass to the reclustered pass to see improvements in accuracy and what grades relate to it
clc;
dir_with_reclustering_pass_grades = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\TEST refinement_pass_results min amp 0 Top 4 Channels grades";
names_of_grades = ["Tight","% Short ISI","Inc", "Temp Mat","Min Bhat","Skewness","TM Updated","Sym of Hist","Amp Category"];
grades_to_check = [2,3,4,8,9,28,29,30,31];
dir_with_reclustering_pass_results = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\TEST refinement_pass_results min amp 0 Top 4 Channels";
generic_blind_pass_grades_dir = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\initial_pass min z_score ! grades";
generic_blind_pass_results_dir = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\initial_pass_results min z_score!";
dir_to_save_figs_to = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\Figures For Blind Vs Reclustered";
make_plots = false;
[changes_in_acc_from_bp_to_rc_some_grades,changes_in_over_from_bp_rc_some_grades,change_in_grades_from_bp_rp_some_grades] =compare_blind_pass_and_reclustered_pass(best_appearences_of_cluster_from_blind_pass,best_appearences_of_cluster_from_reclustered_pass,table_of_accuracy_of_clusters_from_blind_pass,table_of_accuracy_of_clusters_for_reclustered_pass,dir_with_reclustering_pass_grades,grades_to_check,names_of_grades,dir_with_reclustering_pass_results,generic_blind_pass_grades_dir,generic_blind_pass_results_dir,dir_to_save_figs_to,make_plots);

%% concatenate all the plots made in previous part into pdf for simple reading
concatenate_many_plots_updated("D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\Figures For Blind Vs Reclustered\change in accuracy and overlap between blind pass and reclustered pass","Change In Accuracy and Overlap from bp to rc pass.pdf","Plots")
concatenate_many_plots_updated("D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\Figures For Blind Vs Reclustered\change in grades between blind pass and reclustered pass","Change In Grades from bp to rc pass.pdf","Plots")

%% get correlation between all grades and accuracy/overlap 
clc;
[correlation_between_accuracy_and_grades_for_some_grades,correlation_between_overlap_and_grades_for_some_grades] = get_correlation_coeffecients(changes_in_acc_from_bp_to_rc_some_grades,changes_in_over_from_bp_rc_some_grades,change_in_grades_from_bp_rp_some_grades,grades_to_check,names_of_grades);
disp(correlation_between_accuracy_and_grades_for_some_grades);
disp(correlation_between_overlap_and_grades_for_some_grades);
%% get correlation between all grades grades and accuracy/overlap
names_of_all_grades = string(1:42);
all_grades_to_check = 1:42;
clc;
dir_with_reclustering_pass_grades = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\TEST refinement_pass_results min amp 0 Top 4 Channels grades";
names_of_grades = string(1:41);
grades_to_check = 1:41;
dir_with_reclustering_pass_results = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\TEST refinement_pass_results min amp 0 Top 4 Channels";
generic_blind_pass_grades_dir = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\initial_pass min z_score ! grades";
generic_blind_pass_results_dir = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\initial_pass_results min z_score!";
dir_to_save_figs_to = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\Figures For Blind Vs Reclustered";
make_plots = false;
[changes_in_acc_from_bp_to_rc_all_grades,changes_in_over_from_bp_rc_all_grades,change_in_grades_from_bp_rp_all_grades] =compare_blind_pass_and_reclustered_pass(best_appearences_of_cluster_from_blind_pass,best_appearences_of_cluster_from_reclustered_pass,table_of_accuracy_of_clusters_from_blind_pass,table_of_accuracy_of_clusters_for_reclustered_pass,dir_with_reclustering_pass_grades,grades_to_check,names_of_grades,dir_with_reclustering_pass_results,generic_blind_pass_grades_dir,generic_blind_pass_results_dir,dir_to_save_figs_to,make_plots);
%% Display the correlation coeffecient for all grades
clc;
names_of_grades = string(1:41);
minimized_names_of_grades = ["# of spikes","lratio","dur","#spikes/time interval","low/med/high amp","tightness of waveform per cluster","tightness of waveform of per cluster of rep wire","SNR (ring method)","likeliness of burst"];
names_of_grades(6) = minimized_names_of_grades(1);
names_of_grades(11) = minimized_names_of_grades(2);
names_of_grades(25) = minimized_names_of_grades(3);
names_of_grades(26) = minimized_names_of_grades(4);
names_of_grades(31) = minimized_names_of_grades(5);
names_of_grades(35) = minimized_names_of_grades(6);
names_of_grades(36) = minimized_names_of_grades(7);
names_of_grades(40) = minimized_names_of_grades(8);
names_of_grades(41) = minimized_names_of_grades(9);
grades_to_check = 1:41;
[correlation_between_accuracy_and_grades_for_all_grades,correlation_between_overlap_and_grades_for_all_grades] = get_correlation_coeffecients(changes_in_acc_from_bp_to_rc_all_grades,changes_in_over_from_bp_rc_all_grades,change_in_grades_from_bp_rp_all_grades,grades_to_check,names_of_grades);
clc;
disp(correlation_between_accuracy_and_grades_for_all_grades(correlation_between_accuracy_and_grades_for_all_grades{:,"P-Value"}<0.05,:));
%disp(correlation_between_overlap_and_grades_for_all_grades);


%% compute the grades for the refinement pass
all_amps = [0,10,20, 30, 40, 50];
for j=1:1.5%length(all_amps)
    min_amp = all_amps(j);
    for i=3:9
        clc;
        config = spikesort_config; %load the config file;
        config = config.spikesort;
        clc;
        close all;
        dir_with_data = "D:\spike_gen_data\Recordings By Channel Precomputed";
        current_recording = "0_100Neuron300SecondRecordingWithLevel3Noise";
        debug = 0;
        varying_z_scores = [3,4,5,6,7,8,9];
        dir_with_output = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\refinement_pass_results min amp "+string(all_amps(j))+" Top "+string(i)+" Channels";
        dir_to_save_grades_to = dir_with_output+" grades";
        dir_to_save_grades_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_grades_to);
        list_of_tetrodes = strcat("t",string(1:6));
        dir_with_timestamps_and_rvals = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\refinement_pass min amp "+string(all_amps(j))+ " Top "+string(i)+" Channels";
        name_of_grades = ["Tight","% Short ISI","Inc", "Temp Mat","Min Bhat","Skewness","TM Updated","Sym of Hist","Amp Category"];
        relevant_grades = [2,3,4,8,9,28,29,30,31];
        get_grades_for_nth_pass_of_clustering(dir_with_timestamps_and_rvals,dir_with_output,list_of_tetrodes,dir_to_save_grades_to,config,varying_z_scores(i),debug,relevant_grades,name_of_grades)

    end
end


%% find which are neurons in the refined set
clc;
%close all;
dir_with_output = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\refinement_pass_results";
dir_with_pre_computed = "D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise";
varying_z_scores = [4,5,6,7,8,9];
tetrodes_to_check = strcat("t",string(1:192));
min_overlap_percentage = 30;
debug = 0;
grades_that_matter = [2,31,30,32,8,28,29,33,34,9,35,36,37,38,40,41];
names_of_grades =["CV (2)","Amp. (31)","Hist. Sym. (30)","R-Wire Amp(32)","TM(8)","CL. Skew(28)","TM New()","Chance Of M.U.A(33)","Min B-Dist From M.U.A(34)","Min B-Dist To Neighbor(9)","TM Cluster Level(35)","TM Rep Wire Level(36)","Min Bhat Best Dim","Best Dim","SNR","burst ratio(41)"] ;
generic_dir_with_grades = dir_with_output +" grades";
generic_dir_with_outputs = dir_with_output;
dir_to_save_figs_to = "D:\OneDrive - The University of Texas at El Paso\Graded Clusters Z Score 4";
load_previous_attempt = true;
save_results = true;
time_delta = 0.0004;
refinement_pass = true;
dir_to_save_to = "Upper Bound 10 Data";
[best_appearences_of_cluster_3,timestamps_of_best_clusters_3,table_of_overlapping_clusters_3]= id_best_representation_of_clusters(varying_z_scores,tetrodes_to_check,min_overlap_percentage,debug,grades_that_matter,names_of_grades,generic_dir_with_grades,generic_dir_with_outputs,dir_to_save_figs_to,load_previous_attempt,save_results,time_delta,refinement_pass,dir_to_save_to);
original_location_of_the_array = 1:size(best_appearences_of_cluster,1);

%% now compare these best representations to ground truth to see how well they compare
clc;
%close all;
ground_truth_dir = "D:\spike_gen_data\Recording By Channel Ground Truth";
ground_truth_array = load_ground_truth_into_data(ground_truth_dir);
dir_of_timestamps = "D:\spike_gen_data\Recordings By Channel Timestamps\0_100Neuron300SecondRecordingWithLevel3Noise";
timestamps = importdata(dir_of_timestamps+"\timestamps.mat") ;

min_percentage_threshold = 1;
time_delta = 0.004;
debug =0;

table_of_accuracy_of_clusters_2 = compare_timestamps_to_ground_truth_ver_3(ground_truth_array{1},timestamps_of_best_clusters_3,timestamps,time_delta,debug,best_appearences_of_cluster_3);


%% compare the refinement pass to the ground truth 
clc;
%close all;
ground_truth_dir = "D:\spike_gen_data\Recording By Channel Ground Truth";
ground_truth_array = load_ground_truth_into_data(ground_truth_dir);
dir_of_timestamps = "D:\spike_gen_data\Recordings By Channel Timestamps\0_100Neuron300SecondRecordingWithLevel3Noise";
timestamps = importdata(dir_of_timestamps+"\timestamps.mat") ;

min_percentage_threshold = 1;
time_delta = 0.004;
debug =0;

table_of_accuracy_of_clusters = compare_timestamps_to_ground_truth_ver_3(ground_truth_array{1},timestamps_of_best_clusters_2,timestamps,time_delta,debug,best_appearences_of_cluster_2);

%% now look at the resultant tetrodes to see what we get
clc;
close all;
list_of_refined_tetrodes_to_plot = strcat("t",string(1:6));
gen_dir_with_refined_tetrode_results ="D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\refinement_pass_results min amp 0 Top";
gen_dir_with_refined_tetrodes_grades="D:\spike_gen_data\Recordings By Channel Precomputed\0_100Neuron300SecondRecordingWithLevel3Noise\refinement_pass_results min amp 0 Top";
number_of_top_channels = [3,4,5,6,7,8,9];
plot_refined_tetrode_results(gen_dir_with_refined_tetrode_results,gen_dir_with_refined_tetrodes_grades,list_of_refined_tetrodes_to_plot,number_of_top_channels)