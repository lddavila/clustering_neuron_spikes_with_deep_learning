function [] = get_detected_spikes_for_every_channel()
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

fp_to_gt = "/scratch2/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Data/10_600Neuron300SecondRecordingWithLevel10Noise/ground_truth/ground_truth.mat";

gt_data = importdata(fp_to_gt);

config = spikesort_config();
dir_to_save_results = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"rec_10_det_ratio_tables"));


dir_with_channel_data = "/scratch2/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Data/10_600Neuron300SecondRecordingWithLevel10Noise/recordings_by_channel";
tol_amount = 6;
for i=1:length(gt_data)
    save_name = fullfile(dir_to_save_results,"Unit_"+string(i)+".mat");
    if ~isfile(save_name)
    ground_truth_idxs = gt_data{i};
    ratio_table = get_average_amplitude_per_unit_on_each_channel(dir_with_channel_data,ground_truth_idxs,tol_amount);
    par_save(save_name,ratio_table);
    
    end
    disp("Finished "+string(i));
    disp("");
end
end