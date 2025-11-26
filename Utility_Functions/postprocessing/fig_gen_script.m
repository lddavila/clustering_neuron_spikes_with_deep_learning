%% Set up paths
current_script_file_path = mfilename('fullpath');
[current_script_dir,~,~] = fileparts(current_script_file_path);
cd(current_script_dir);

% first let's put all files on the path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
disp("Finished setting path")

%% get a config file
config = spikesort_config();

%% import any data you need to create figures
mixed_bp_table_6_7_8 = importdata(fullfile(config.base_file_path,"Data","mixed_bp_table_6_7_8.mat"));
%% 
aligned = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\6_600Neuron300SecondRecordingWithLevel6Noise\initial_pass_results min z_score 3\t1 aligned.mat");
%% now create figures
%meaningful title
    %what function was called to create this
    %what data was put into it 
    %any parameters the function was called with
%Axes labeled (units, channel, something significant that leads to obvious
%understanding)
%legends 
%every figure should be saved as svg 
example_1 = mixed_bp_table_6_7_8(mixed_bp_table_6_7_8{:,"Max_Overlap_Unit"}==2 & mixed_bp_table_6_7_8{:,"recording_name"}== "6_600Neuron300SecondRecordingWithLevel6Noise",:)