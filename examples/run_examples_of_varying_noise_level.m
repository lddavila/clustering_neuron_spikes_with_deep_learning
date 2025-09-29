%% SKIPPABLE STEP: HERE I SET THE job location to a directory, need not be run generally
c = parcluster('local');
% Put JobStorageLocation on node-local temp, NOT on GPFS
tmp = getenv('TMPDIR'); if isempty(tmp), tmp = tempdir; end
c.JobStorageLocation = fullfile(tmp, sprintf('matlabJobStorage_%s', char(java.util.UUID.randomUUID)));
if ~exist(c.JobStorageLocation,'dir'), mkdir(c.JobStorageLocation); end
disp("Num worksers available:"+string(c.NumWorkers));
parpool("Processes", c.NumWorkers);

%% STEP 1: Add functions to your path
examples_dir = cd("..");
addpath(genpath(pwd));
cd(examples_dir);
disp("Finished Adding path")
default_dir_parts = ["_600Neuron300SecondRecordingWithLevel","Noise"];
%%
for i=1:5
    % step 2: Get the config Necessary for current Example
    config = spikesort_config();
    config.RECORDING_NAME = string(i)+default_dir_parts(1)+string(i)+default_dir_parts(2);
    config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,config.RECORDING_NAME);
    startup;
    disp("Finished Setting Recording Name")
    disp("precomputed dir")
    disp(config.BLIND_PASS_DIR_PRECOMPUTED);
    % (OPTIONAL STEP 2 CONTINUED) SET THE filepath of the ground truth files if your recording is simulated and they are available
    config.GT_FP = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
    config.TIMESTAMP_FP = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
    config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"recordings_by_channel");
    disp("Finished Setting directories")
   
    % Step 3: Download Necessary Data
    %run_me_to_download_data("10.7910/DVN/JWATDZ",config,true,config.RECORDING_NAME);
    disp("Finished Downloading Data");
    % Step 4: run the blind pass with a various min_z_score (cut threshold)
    very_beginning_time = tic;
    [blind_pass_table,fp_to_bp_table,config] = run_entire_clustering_algorithm_ver_2(config);

    %add the recording name to the blind pass table
    blind_pass_table.recording_name = repelem(config.recording_name,size(blind_pass_table,1),1);
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
        save(fp_to_bp_table,"blind_pass_table");
    else
        disp("Overlap are already in your table.")
        disp("To recompute delete finished_adding_overlap_and_accuracy.txt");
    end
    disp("Finished Saving Accuracy");
    end_time = toc(beginning_time);
    fprintf("Finished adding overlap and accuracy columns it took %.2f seconds\n",end_time)
    % Step 6: Get accuracy category prediction using grades + universal rank neural network
    beginning_time = tic;
    config.TIME_DELTA = 0.0002; %changing back to the time delta used to train nn
    if ~isfile(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"finished_adding_accuracy_cat_predictions.txt"))
        blind_pass_table = add_accuracy_cat_pred_from_nn(blind_pass_table,config);
        end_time = toc(beginning_time);
        save(fp_to_bp_table,"blind_pass_table");
    else
        disp("Accuracy category and mean waveform already exist. Will skip adding them again.")
        disp("To repredict delete finished_adding_accuracy_cat_predictions.txt")
    end
    fprintf("Finished adding accuracy cat predictions based on grades and universal rank it took %.2f seconds\n",end_time)
    % step 7: Get Accuracy category prediction using mean waveform neural network
    beginning_time = tic;
    if ~isfile(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"finished_adding_accuracy_cat_based_on_wf.txt"))
        blind_pass_table = add_mean_waveform_pred_col(blind_pass_table,config);
        end_time=toc(beginning_time);
        save(fp_to_bp_table,"blind_pass_table");
    else
        disp("Accuracy category based on waveform predictions already exist. Skipping.")
        disp("To repredict delete finished_adding_accuracy_cat_based_on_wf.txt");
    end
    fprintf("Finished adding accuracy cat predictions based on mean waveform it took %.2f seconds\n",end_time)
    % step 8: Get Letter Grade
    beginning_time = tic;
    blind_pass_table = add_letter_grade_based_on_nn(blind_pass_table);
    end_time = toc(beginning_time);
    save(fp_to_bp_table,"blind_pass_table");
    fprintf("Finished Adding Letter Grade based on mean waveform and grades and universal rank prediction. It took %f seconds\n",end_time);
    % Step 8: Use Accuracy Prediction Neural Network to filter out any MUA clusters that made it past the first filter
    bp_table_only_neur_filtered = blind_pass_table(blind_pass_table{:,"grades_pred"}>0,:);

    % Step 9: Merge neurons into groups that represent the same underlying unit
    beginning_time = tic;
    config.TIME_DELTA = 0.0002; %a stricter time delta then available on the neural network
    clusters_organized_by_same_group = determine_which_blind_pass_neurons_overlap_parallel(bp_table_only_neur_filtered,config);
    end_time = toc(beginning_time);
    fprintf("Finished merging clusters it took %f seconds\n",end_time)
    % Step 10: Save Results of merging
    clusters_organized_by_same_group_with_filter_fp = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table_organized_into_same_groups_with_filter");
    create_a_file_if_it_doesnt_exist_and_ret_abs_path(clusters_organized_by_same_group_with_filter_fp);
    save(fullfile(clusters_organized_by_same_group_with_filter_fp,"clusters_organized_by_same_group.mat"),"clusters_organized_by_same_group");
    % Step 11: Merge Neurons into groups without step (for testing purposes)
    clusters_organized_by_same_group_without_filter = determine_which_blind_pass_neurons_overlap_parallel(blind_pass_table_only_neurons, config);

    % step 12 : Save the results of step 11
    clusters_organized_by_same_group_without_filter_fp = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table_organized_into_same_groups_without_filter");
    create_a_file_if_it_doesnt_exist_and_ret_abs_path(clusters_organized_by_same_group_without_filter_fp);
    save(fullfile(clusters_organized_by_same_group_without_filter_fp,"clusters_organized_by_same_group_without_filter.mat"),"clusters_organized_by_same_group_without_filter");
end
