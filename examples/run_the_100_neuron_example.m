%% STEP 1: Add functions to your path
examples_dir = cd("..");
addpath(genpath(pwd));
cd(examples_dir);

%% step 2: Get the config Necessary for current Example
config = spikesort_config();
%% Step 3 Download Necessary Data
run_me_to_download_data("9c2e6016-544e-48b9-906c-474836e003fe","10.70122/FK2/BVPIJO",config,false);
%% run the blind pass with a various min_z_score (cut threshold) 
run_entire_clustering_algorithm_ver_2(config);
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
