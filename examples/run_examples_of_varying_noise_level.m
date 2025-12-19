
%% STEP 1: Add functions to your path
examples_dir = cd("..");
addpath(genpath(pwd));
cd(examples_dir);
disp("Finished Adding path")
default_dir_parts = ["_600Neuron300SecondRecordingWithLevel","Noise"];
config = spikesort_config();
%% SKIPPABLE STEP: HERE I SET THE job location to a directory, need not be run generally
% Put JobStorageLocation on node-local temp, NOT on GPFS
if contains(pwd,"10595")
    c = parcluster('local'); 
   parpool(c,56)
elseif ~contains(config.base_file_path,"afriedman")
    c = parcluster('local');
    parpool(c.NumWorkers)
end
%%
% step 2: Get the config Necessary for current Example
if contains(config.base_file_path,"cnheaton")
    beginning = 6;
    the_end = 10;
elseif contains(config.base_file_path,"afriedman")
    beginning=1;
    the_end = 5;
    parpool('local_40', 40);
else
    beginning = 6;
    the_end = 10;
end
for i=beginning:the_end
    config = spikesort_config();
    config.RECORDING_NAME = string(i)+default_dir_parts(1)+string(i)+default_dir_parts(2);
    config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,config.RECORDING_NAME);
    disp("Recording Name");
    disp(config.RECORDING_NAME)
    startup;
    if contains(pwd,"10595")
        config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
        config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
        config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
    else
        config.GT_FP = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
        config.TIMESTAMP_FP = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
        config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"recordings_by_channel");
    end
    % (OPTIONAL STEP 2 CONTINUED) SET THE filepath of the ground truth files if your recording is simulated and they are available

    

    % disp("TS fp");
    % disp(config.TIMESTAMP_FP);
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
    config.TIME_DELTA = 0.0002; %changing time delta to match kilosort4 delta used when computing matching score
    timestamps = importdata(config.TIMESTAMP_FP);
    if ~isfile(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"finished_adding_overlap_and_accuracy.txt"))
        blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,config,timestamps);
        par_save(fp_to_bp_table,blind_pass_table);
        disp("Finished finding max overlap unit")
        blind_pass_table= add_accuracy_col(config,blind_pass_table);
        par_save(fp_to_bp_table,blind_pass_table);
    else
        disp("Overlap are already in your table.")
        disp("To recompute delete finished_adding_overlap_and_accuracy.txt");
    end
    disp("Finished Saving Accuracy");
    end_time = toc(beginning_time);
    fprintf("Finished adding overlap and accuracy columns it took %.2f seconds\n",end_time)

    beginning_time = tic;
    if ~isfile(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"finished_creating_cluster_groups_without_tags.txt"))
        default_cluster_groups = simple_grouping_parallel(blind_pass_table,config);
        par_save(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"default_cluster_groups.mat"),default_cluster_groups)
        file_name = "finished_creating_cluster_groups_without_tags.txt";
        file_id = fopen(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,file_name),'w');
        fclose(file_id);
    else
        default_cluster_groups = importdata(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"default_cluster_groups.mat"));
        disp("groups already formed")
    end
    disp("Finished forming groups")
    end_time = toc(beginning_time);
    fprintf("Finished forming groups it took %.2f seconds\n",end_time)

    beginning_time = tic;
    % if ~isfile(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"finished_creating_cluster_groups_with_tags"))
    %     new_groups = add_group_tags_col(default_cluster_groups,config);
    %     par_save(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"revised_cluster_groups.mat"),new_groups)
    %     file_name = "finished_creating_cluster_groups_with_tags.txt";
    %     file_id = fopen(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,file_name),'w');
    %     fclose(file_id);
    % else
    %     disp("new groups already formed");
    %     new_groups = importdata(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"revised_cluster_groups.mat"));
    % end
    % end_time = toc(beginning_time);
    % fprintf("Finished Getting Group revisions it took %.2f seconds \n",end_time);
    
end
