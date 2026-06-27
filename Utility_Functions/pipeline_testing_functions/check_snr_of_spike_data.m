function [] = check_snr_of_spike_data(config,spike_windows,tetr_or_ch_string,varargin)

ground_truth_cell_array = config.ground_truth_cell_array;
parent_dir =create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.dir_to_save_debug_files_to,"snr"));



%first thing we probably want to check is if we're operating on a channel
%or tetrode level
%this will change how we save things
if all(spike_windows(:,3)==spike_windows(1,3)) %indicates a channel since all spikes come from the same channel
    save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(parent_dir,"channels"));
else %indicates a tetrode since spikes come from multiple channels 
    save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(parent_dir,"tetrodes"));
end
if isempty(varargin)
    save_name = fullfile(save_dir,tetr_or_ch_string+".mat");
else
    save_name = fullfile(save_dir,tetr_or_ch_string+"_"+string(varargin{1})+"_stage_"+string(config.stage_counter)+".mat");
end
if isfile(save_name) 
    return; %we skip channels because they're more of a one and done
end

%okay now that we have our save dir set up we can check the locations of
%the peaks in spike windows against each item in the cell array
tol_amount = 3; %equiavlent to about .1 milliseconds
unit_detection_raw_num= zeros(length(ground_truth_cell_array),1);
for i=1:length(ground_truth_cell_array)
    is_in_spike_windows = ismembertol(double(ground_truth_cell_array{i}),double(spike_windows(:,4)),tol_amount,'Datascale',1);
    unit_detection_raw_num(i) = sum(is_in_spike_windows);
end

%now that we have counted all units that appear on this spike I think it
%would be useful to count how many spikes appear on this channel or tetrode
signal_to_noise_ratio = sum(unit_detection_raw_num) / size(spike_windows,1);

snr_struct = struct();
snr_struct.signal_to_noise_ratio = signal_to_noise_ratio;
snr_struct.unit_detection_raw_num = unit_detection_raw_num;
snr_struct.num_spikes = size(spike_windows,1);

par_save(save_name,snr_struct);

end