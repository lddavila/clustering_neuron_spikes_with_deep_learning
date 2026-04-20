%% set path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%% get a config
config = spikesort_config();

% set params on the config
config.RECORDING_NAME = "10_600Neuron300SecondRecordingWithLevel10Noise";
config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"test_ic_3_"+config.RECORDING_NAME);
config.BLIND_PASS_DIR_PRECOMPUTED_ONLY_END = "test_ic_"+config.RECORDING_NAME;
disp("Recording Name");
disp(config.RECORDING_NAME)
config.debug_with_ground_truth = true;
startup;


ext_drive_fp = "E:";
config.GT_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"ground_truth","ground_truth.mat");
config.TIMESTAMP_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(ext_drive_fp,config.RECORDING_NAME,"recordings_by_channel");
% config.ART_TETR_ARRAY = config.ART_TETR_ARRAY(1,:);
 config.BLIND_PASS_DIR_PRECOMPUTED = strrep(config.BLIND_PASS_DIR_PRECOMPUTED,fullfile(config.base_file_path,"Default_Results_Dir"),ext_drive_fp);
config.Multipliers = 3:1:15;
%% run the spike sorter
[blind_pass_table,fp_to_bp_table,config] = run_entire_clustering_algorithm_ver_2(config);

%% calculate the accuracy for the results
% beginning_time = tic;
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

    











