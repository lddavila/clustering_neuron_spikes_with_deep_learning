function [] = run_full_pass(which_recording,number_of_channels,varargin)
%meant to run on TACC and only TACC, not modified for anything else
%this function is meant to run the same examples, but uses the new spike
%detection method copied from ironclust
% STEP 1: Add functions to your path
home_dir = cd("..");
cd("..");
disp(pwd);
addpath(genpath(fullfile(pwd,"Utility_Functions")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Grading_scripts")));
% addpath(fullfile(pwd,"startup.m"))
cd(home_dir);
disp("Finished Adding path")
default_dir_parts = ["_600Neuron300SecondRecordingWithLevel","Noise"];
currentPool = gcp('nocreate');
if isempty(currentPool)
    cluster = parcluster("Processes");
    time_start = tic();
    if contains(pwd,"10595")
        poolobj = parpool(cluster, 4);
    else
        poolobj = parpool(cluster, 8);
    end
    time_end = toc(time_start);
    fprintf("Starting the parallel pool took %.2f seconds\n",time_end)
end

beginning = which_recording;
the_end = which_recording+0.5;
rng(0);

for i=beginning:the_end
    try
        config = spikesort_config();
        config.RECORDING_NAME = string(i)+default_dir_parts(1)+string(i)+default_dir_parts(2);


        config.use_new_spike_detection = false;
        config.use_bandpass = false;
        if isempty(varargin)
            config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"full_set_"+config.RECORDING_NAME+"_"+string(number_of_channels)+"_ch");
        else
            ext_drive_path = "F:\cluster_data";
            config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(ext_drive_path,"new_features_subset_"+config.RECORDING_NAME+"_"+string(number_of_channels)+"_ch");
        end
        split_fp = split(config.BLIND_PASS_DIR_PRECOMPUTED,filesep);
        config.BLIND_PASS_DIR_PRECOMPUTED_ONLY_END = split_fp(end);
        config.use_new_features = true;
        config.stop_before_grading = false;
        config.which_new_feature = "prominance_and_peak_width_width_over_height";
        config.spikesort.which_new_feature = config.which_new_feature;



        disp("Recording Name");
        disp(config.RECORDING_NAME)
        % config.prc_tile
        startup;
        %get a new art_tetrode_array and set it in the config
        config.ART_TETR_ARRAY = build_channel_configs(number_of_channels,config);
         
        if contains(pwd,"10595")
            config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
            config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
            config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
        elseif contains(pwd,"C:\Users\ldd77\") && isempty(varargin)
            % ext_drive_fp = "F:";
            config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
            config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
            config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
            
        elseif contains(pwd,"E:\clustering_neuron_spikes_with_deep_learning")%running on inscopix
            ext_drive_fp = "E:";
            config.GT_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"ground_truth","ground_truth.mat");
            config.TIMESTAMP_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"timestamps","timestamps.mat");
            config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(ext_drive_fp,config.RECORDING_NAME,"recordings_by_channel");
        else
            config.GT_FP = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
            config.TIMESTAMP_FP = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
            config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"recordings_by_channel");
        end
        disp("Finished Setting directories")

        very_beginning_time = tic;
        config.ground_truth_cell_array = importdata(config.GT_FP);
        config.spikesort.ground_truth_cell_array = importdata(config.GT_FP);
        config.debug_with_ground_truth = true;
        config.run_full_clustering = true;
        config.percentiles_to_use = [80:-20:20];
        config.spikesort.fp_to_ch_to_units = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\new_features_subset_10_600Neuron300SecondRecordingWithLevel10Noise_2_ch\DEBUG\table_of_best_rep.mat";
        [blind_pass_table,fp_to_bp_table,config] = run_entire_clustering_algorithm_ver_2(config);


        end_time = toc(very_beginning_time);
        fprintf("Finished running blind pass it took %f seconds\n",end_time)
    catch ME
        fprintf(2, getReport(ME, 'extended', 'hyperlinks', 'on'));
    end
end
end