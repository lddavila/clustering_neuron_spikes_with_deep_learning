function [spike_slices,spike_slices_in_samples_format,cluster_idx,time_slices] = get_raw(chan_of_art_tetrode,dir_with_chan_recordings,number_of_dps_per_slice,scale_factor,min_z_score,config,spike_windows_for_current_tetrode,og_cluster_idx,timing_matrix)
channels_data = cell(length(chan_of_art_tetrode),1);
for i=1:length(chan_of_art_tetrode)
    current_channel = chan_of_art_tetrode(i);
    current_channel_recording_file_name = fullfile(dir_with_chan_recordings,"c"+string(current_channel)+".mat");
    current_channel_data = load(current_channel_recording_file_name);
    the_field_name = string(fieldnames(current_channel_data));
    current_channel_data = current_channel_data.(the_field_name);
    current_channel_data = ( current_channel_data* scale_factor).';
    channels_data{i} = current_channel_data;
end

[sorted_spike_windows_for_current_tetrode,new_cluster_locs]= sortrows(spike_windows_for_current_tetrode,[1,2,4]);
cluster_idx = find(ismember(new_cluster_locs,og_cluster_idx));
sorted_spike_windows_for_current_tetrode(any(sorted_spike_windows_for_current_tetrode==0,2),:) = []; %any rows that have a zero must be removed
%this is because zero is an invalid index and indicates something went wrong

%remove any rows whose fifth column doesn't meet the minimum z score /
%multiplier threshold
if ~config.use_new_spike_detection
    sorted_spike_windows_for_current_tetrode(abs(sorted_spike_windows_for_current_tetrode(:,5))<min_z_score,:) = [];
else

end
%spike_slices: must be sorted in such a way that when you run the following code the output matches
%[numwires, numspikes, numdp] = size(raw);
%numwires: number of channels
%numspikes: number of spikes
%numdp: number of datapoints

%
spike_slices = zeros(length(chan_of_art_tetrode),size(sorted_spike_windows_for_current_tetrode,1),number_of_dps_per_slice);
time_slices = zeros(size(sorted_spike_windows_for_current_tetrode,1),number_of_dps_per_slice);

%spike_slices_in_samples_format is the same data as in spike_slices, but permutted differently
%   Samples: spike waveform samples formatted as a 32xMxN matrix of data
%       points, where M is the number of subchannels (wires) in the spike
%       file (NTT M = 4, NST M = 2, NSE M = 1). These values are in AD
%       counts.
spike_slices_in_samples_format =zeros(number_of_dps_per_slice,size(chan_of_art_tetrode,2),size(sorted_spike_windows_for_current_tetrode,1));
spiking_channels = cell(1,size(sorted_spike_windows_for_current_tetrode,1));




simple_channel_list = 1:numel(chan_of_art_tetrode);

for i=1:size(sorted_spike_windows_for_current_tetrode,1)
    current_window = sorted_spike_windows_for_current_tetrode(i,:);
    if current_window(1,1) == current_window(1,2) 
        continue;
    end
    current_timing_slice = timing_matrix(current_window(1,1):current_window(1,2) -1);
    time_slices(i,:) = current_timing_slice;
    for j=simple_channel_list
        spike_slices(j,i,:) = channels_data{j}(current_window(1,1) :current_window(1,2) -1);
        spike_slices_in_samples_format(:,j,i) = channels_data{j}(current_window(1,1):current_window(1,2)-1);
    end
    spiking_channels{i} = current_window(3);
end

end