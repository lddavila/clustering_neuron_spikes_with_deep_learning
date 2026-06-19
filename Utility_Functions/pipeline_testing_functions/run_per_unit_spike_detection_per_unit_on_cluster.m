function [] = run_per_unit_spike_detection_per_unit_on_cluster()
% add the path
home_dir = cd("..");
cd("..");
addpath(genpath(fullfile(pwd,"Utility_Functions")));
addpath(genpath(fullfile(pwd,"clustering-master")));
cd(home_dir);
disp("Finished adding path")

% get the config
config = spikesort_config();
config.Multipliers = 1:1:13;
disp("Finished setting multipliers")

config.RECORDING_NAME = "10_600Neuron300SecondRecordingWithLevel10Noise";
config.BLIND_PASS_DIR_PRECOMPUTED = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"test_ic_"+config.RECORDING_NAME));
config.BLIND_PASS_DIR_PRECOMPUTED_ONLY_END = "test_ic_"+config.RECORDING_NAME;
disp("Recording Name");
disp(config.RECORDING_NAME)
startup;


precomputed_dir = config.BLIND_PASS_DIR_PRECOMPUTED;


config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
disp("Finished setting config parameters");
ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);
disp('Finished getting orrdered list of channels')
dir_to_store_filtered_data = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"rec_10_filtered_data"));
apply_filter(ordered_list_of_channels,config,dir_to_store_filtered_data,config.DIR_WITH_OG_CHANNEL_RECORDINGS)
dir_with_channel_recordings = dir_to_store_filtered_data; 
disp("Finished applying filter")
% run the spike detection
scale_factor = -1;
config.ALREADY_DONE_FILES = [""];
lowest_bound_spikes_per_channel_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"spikes_per_channel min_mult "+string(min(config.Multipliers))));

[multipliers_in_mv,pk_locs_cell_array,pk_vals_cell_array]= use_ic_spike_det(lowest_bound_spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,scale_factor,config,config.Multipliers);
config.Multipliers_in_mv = multipliers_in_mv;
disp("finished getting the spikes per channel and multipliers in mv")
% get the ground truth
ground_truth = importdata(config.GT_FP);
disp("Finished importing the ground truth");

% for each ground unit see what the detection ratio is
tol_amount = 6; %equal to about .2 milliseconds
for i=1:length(ground_truth)
    current_ground_truth = ground_truth{i};

    all_channels = 1:1:length(pk_locs_cell_array);
    all_multiplier_idxs = 1:1:length(config.Multipliers);

    all_combinations_of_mult_and_channels = combinations(all_channels,all_multiplier_idxs);
    detection_ratio = zeros(height(all_combinations_of_mult_and_channels),1);
    mean_amplitude_of_detected_spikes = zeros(height(all_combinations_of_mult_and_channels),1);
    multiplier_in_mv_col = zeros(height(all_combinations_of_mult_and_channels),1);
    median_amplitude_of_detected_spikes = zeros(height(all_combinations_of_mult_and_channels),1);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = height(all_combinations_of_mult_and_channels);
    print_status_bar(num_iterations,"doing_combinations")
    for j=1:height(all_combinations_of_mult_and_channels)
        current_channel_peak_locs = pk_locs_cell_array{all_combinations_of_mult_and_channels{j,"all_channels"}};
        current_channel_peak_amps = pk_vals_cell_array{all_combinations_of_mult_and_channels{j,"all_channels"}};
        current_channel_thresholds_in_mv = multipliers_in_mv{all_combinations_of_mult_and_channels{j,"all_channels"}};
        current_channel_threshold_level = current_channel_thresholds_in_mv(all_combinations_of_mult_and_channels{j,"all_multiplier_idxs"});
        
        filtered_peak_locs = current_channel_peak_locs(abs(current_channel_peak_amps) >= abs(current_channel_threshold_level));
        filtered_peak_amps = current_channel_peak_amps(abs(current_channel_peak_amps) >= abs(current_channel_threshold_level));
        [is_tp,loc_in_filtered_peaks]= ismembertol(double(round(current_ground_truth)), double(round(filtered_peak_locs)),tol_amount,'DataScale',1);
        detection_ratio(j) = (sum(is_tp) / length(current_ground_truth)) * 100;
        mean_amplitude_of_detected_spikes(j) = mean(abs(filtered_peak_amps(loc_in_filtered_peaks(loc_in_filtered_peaks~=0))));
        multiplier_in_mv_col(j) = current_channel_threshold_level;
        median_amplitude_of_detected_spikes(j) = median(abs(filtered_peak_amps(loc_in_filtered_peaks(loc_in_filtered_peaks~=0))));
        send(q,[]);
    end

    all_combinations_of_mult_and_channels.detection_ratio = detection_ratio;
    all_combinations_of_mult_and_channels.mult_in_mv = multiplier_in_mv_col;
    all_combinations_of_mult_and_channels.mean_amplitude = mean_amplitude_of_detected_spikes;
    all_combinations_of_mult_and_channels.median_amp = median_amplitude_of_detected_spikes;
    
    all_combinations_of_mult_and_channels = sortrows(all_combinations_of_mult_and_channels,["detection_ratio","mean_amplitude"],"descend");
    
    par_save(fullfile(precomputed_dir,"Unit_"+string(i)+".mat"),all_combinations_of_mult_and_channels)
    disp('Finished '+string(i));
end

end