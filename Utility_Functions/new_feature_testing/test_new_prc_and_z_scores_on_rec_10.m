function [] = test_new_prc_and_z_scores_on_rec_10(which_recording,varargin)
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
if ~isempty(varargin) && isempty(currentPool)
    cluster = parcluster("Processes");
    num_workers = max(1, floor(cluster.NumWorkers / 8));
    fprintf("Have %i workers\n",num_workers);
    time_start = tic();
    poolobj = parpool(cluster, 5);
    time_end = toc(time_start);
    fprintf("Starting the parallel pool took %.2f seconds\n",time_end)
end

beginning = which_recording;
the_end = which_recording+0.5;
number_of_channels_to_use = 4;
for k=1:length(number_of_channels_to_use)
    current_number_of_channels = number_of_channels_to_use(k);
    for i=beginning:the_end
        try
            config = spikesort_config();
            config.run_full_clustering = true;
            config.percentiles_to_use = [1];
            config.spikesort.NUM_ITERATIONS = 5;
            config.RECORDING_NAME = string(i)+default_dir_parts(1)+string(i)+default_dir_parts(2);
            config.DEFAULT_CLUSTERING_Z_SCORES = [3,4,5,6,7,8,9];

            if ~isempty(varargin)
                if varargin{2} == "ic"
                    %overwrite the z scores
                    config.DEFAULT_CLUSTERING_Z_SCORES = [1];
                    config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"date_test_05_27_"+config.RECORDING_NAME+"_"+string(current_number_of_channels)+"_ch");
                else
                    config.use_new_spike_detection = false;
                    config.use_bandpass = false;
                    config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"std_20_all_pmv_"+config.RECORDING_NAME+"_"+string(current_number_of_channels));
                    %testing feature
                    config.NUM_OF_STD_ABOVE_MEAN = 20;
                end
            end



            %
            disp("Recording Name");
            disp(config.RECORDING_NAME)
            % config.prc_tile
            startup;
            %get a new art_tetrode_array and set it in the config
            % new_tetrode_array = build_channel_configs(current_number_of_channels,config);
            % config.ART_TETR_ARRAY = new_tetrode_array;
            if contains(pwd,"10595")
                config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
                config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
                config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
            elseif contains(pwd,"C:\Users\ldd77\")
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
            % (OPTIONAL STEP 2 CONTINUED) SET THE filepath of the ground truth files if your recording is simulated and they are available

            disp("Finished Setting directories")

            % Step 3: Download Necessary Data
            %run_me_to_download_data("10.7910/DVN/JWATDZ",config,true,config.RECORDING_NAME);
            disp("Finished Downloading Data");
            % Step 4: run the blind pass with a various min_z_score (cut threshold)
            very_beginning_time = tic;
            config.ground_truth_cell_array = importdata(config.GT_FP);
            config.debug_with_ground_truth = true;

            [blind_pass_table,fp_to_bp_table,config] = run_entire_clustering_algorithm_ver_2(config);


            end_time = toc(very_beginning_time);
            fprintf("Finished running blind pass it took %f seconds\n",end_time)
            % (OPTIONAL STEP 5 CONTINUED) Get max overlap unit and accuracy cols for the neurons
            % This is only possible if your recording is simulated and the ground truth
            % is provided
            % in this example the data is simulated and the ground truth is available
            beginning_time = tic;
            config.TIME_DELTA = 0.0002; %changing time delta to match kilosort4 delta used when computing matching score
            timestamps = importdata(config.TIMESTAMP_FP);
            if ~isfile(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"finished_adding_overlap_and_accuracy.txt"))
                blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,config,timestamps);
                blind_pass_table= add_accuracy_col(config,blind_pass_table);
                par_save(fp_to_bp_table,blind_pass_table);
            else
                disp("Overlap are already in your table.")
                disp("To recompute delete finished_adding_overlap_and_accuracy.txt");
            end
            disp("Finished Saving Accuracy");
            end_time = toc(beginning_time);
            fprintf("Finished adding overlap and accuracy columns it took %.2f seconds\n",end_time)

        catch ME
            fprintf(2, getReport(ME, 'extended', 'hyperlinks', 'on'));
        end
    end
end
end