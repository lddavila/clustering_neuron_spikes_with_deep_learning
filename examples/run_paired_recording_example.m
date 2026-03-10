function [] = run_paired_recording_example(which_recording)
% STEP 1: Add functions to your path
examples_dir = cd("..");
addpath(genpath(pwd));
cd(examples_dir);
disp("Finished Adding path")
default_dir_parts = ["_600Neuron300SecondRecordingWithLevel","Noise"];
config = spikesort_config();
% SKIPPABLE STEP: HERE I SET THE job location to a directory, need not be run generally
% Put JobStorageLocation on node-local temp, NOT on GPFS
if contains(pwd,"10595")
    beginning = tic;
    c = parcluster('local');
    parpool(15,'IdleTimeout', inf);
    c.JobStorageLocation = pwd;
    disp(c.JobStorageLocation);
    % parpool(c.NumWorkers, 'IdleTimeout', inf);
    ending_time = toc(beginning);
    fprintf("Starting Parallel Pool took %.2f seconds",ending_time);
elseif contains(config.base_file_path,"afriedman")
    beginning = tic;
    disp("Using the afriedman")
    c = parcluster('local');
    
    c.JobStorageLocation = pwd;
    disp("Job Storage Location");
    disp(c.JobStorageLocation);
    parpool(c.NumWorkers, 'IdleTimeout', inf);
    ending_time = toc(beginning);
    fprintf("Starting Parallel Pool took %.2f seconds",ending_time);
elseif contains(config.base_file_path,"C:\Users\ldd77\") %for local testing

end
% step 2: Get the config Necessary for current Example

beginning = which_recording;
the_end = which_recording+.5;
number_of_channels_to_use = [4,1,2,3,5,6];
for k=1:length(number_of_channels_to_use)
    current_number_of_channels = number_of_channels_to_use(k);
    for i=beginning:the_end
        % try
        config = spikesort_config();
        config.RECORDING_NAME = "cell_"+string(i);
        config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"ic_"+config.RECORDING_NAME+"_"+string(current_number_of_channels)+"_channels");
        disp("Recording Name");
        disp(config.RECORDING_NAME)
        startup;
        %get a new art_tetrode_array and set it in the config
        new_tetrode_array = build_channel_configs(current_number_of_channels,config);
        if current_number_of_channels ~= 4
            config.ART_TETR_ARRAY = new_tetrode_array;
        end
        if contains(pwd,"10595")
            config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
            config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
            config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
        elseif contains(pwd,"C:\Users\ldd77\")
            ext_drive_fp = "F:";
            config.GT_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"ground_truth","ground_truth.mat");
            config.TIMESTAMP_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"timestamps","timestamps.mat");
            config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(ext_drive_fp,config.RECORDING_NAME,"recordings_by_channel");
            % config.ART_TETR_ARRAY = config.ART_TETR_ARRAY(1,:);
            config.BLIND_PASS_DIR_PRECOMPUTED = strrep(config.BLIND_PASS_DIR_PRECOMPUTED,fullfile(config.base_file_path,"Default_Results_Dir"),"F:");
        else

            config.GT_FP = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
            config.TIMESTAMP_FP = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
            config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"recordings_by_channel");
        end
        % (OPTIONAL STEP 2 CONTINUED) SET THE filepath of the ground truth files if your recording is simulated and they are available




        disp("TS fp");
        disp(config.TIMESTAMP_FP);
        disp("Finished Setting directories")

        % Step 3: Download Necessary Data
        %run_me_to_download_data("10.7910/DVN/JWATDZ",config,true,config.RECORDING_NAME);
        disp("Finished Downloading Data");
        % Step 4: run the blind pass with a various min_z_score (cut threshold)
        very_beginning_time = tic;
        [blind_pass_table,fp_to_bp_table,config] = run_entire_clustering_algorithm_ver_2(config);


        end_time = toc(very_beginning_time);
        fprintf("Finished running blind pass it took %f seconds\n",end_time)
        % (OPTIONAL STEP 5 CONTINUED) Get max overlap unit and accuracy cols for the neurons
        % This is only possible if your recording is simulated and the ground truth
        % is provided
        % in this example the data is simulated and the ground truth is available
        beginning_time = tic;
        config.TIME_DELTA = 0.002; %changing time delta to match kilosort4 delta used when computing matching score
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
        % catch ME
        %     fprintf(2, getReport(ME, 'extended', 'hyperlinks', 'on'));
        % end
    end
end
end