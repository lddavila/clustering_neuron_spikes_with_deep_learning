function [spike_slices] = reassemble_spikes(spike_windows,config,chan_of_art_tetrode,dir_with_chan_recordings)
scale_factor = config.SCALE_FACTOR;
number_of_dps_per_slice = config.NUM_DPTS_TO_SLICE;
channels_data = cell(length(chan_of_art_tetrode),1);

for i=1:length(chan_of_art_tetrode)
    current_channel = chan_of_art_tetrode(i);
    current_channel_recording_file_name = fullfile(dir_with_chan_recordings,"c"+string(current_channel)+".mat");
    current_channel_data = load(current_channel_recording_file_name);
    current_channel_data = current_channel_data.(string(fields(current_channel_data)));
    current_channel_data = ( current_channel_data* scale_factor).';
    if size(current_channel_data,1) > size(current_channel_data,2)
        current_channel_data = current_channel_data.';
    end
    channels_data{i} = current_channel_data;
    spike_windows(spike_windows(:,3)==current_channel & any(spike_windows,2)>length(current_channel_data),:) = [];
end
all_channel_sizes =  cell2mat(cellfun(@size, channels_data, 'UniformOutput', false));
min_ch_size = min(all_channel_sizes);
min_ch_size = min_ch_size(2);

timing_matrix = importdata(config.TIMESTAMP_FP);
spike_windows(any(spike_windows>min_ch_size,2),:) = [];
spike_windows(spike_windows(:,2)<1,:) = [];
spike_windows(any(spike_windows(:,2)==0,2),:) = [];
spike_windows_for_current_tetrode = spike_windows;

[sorted_spike_windows_for_current_tetrode,new_row_order] = sortrows(spike_windows_for_current_tetrode,[1,3]);
sorted_spike_windows_for_current_tetrode(any(sorted_spike_windows_for_current_tetrode==0,2),:) = []; %any rows that have a zero must be removed
%this is because zero is an invalid index and indicates something went wrong

%remove any rows whose fifth column doesn't meet the minimum z score /
%multiplier threshold
if ~config.use_new_spike_detection
    sorted_spike_windows_for_current_tetrode(abs(sorted_spike_windows_for_current_tetrode(:,5))<min_z_score,:) = [];
else

end

%
spike_slices = zeros(size(chan_of_art_tetrode,2),size(sorted_spike_windows_for_current_tetrode,1),number_of_dps_per_slice);

time_slices = zeros(size(sorted_spike_windows_for_current_tetrode,1),number_of_dps_per_slice);
spiking_channels = cell(1,size(sorted_spike_windows_for_current_tetrode,1));


sliced_spike_windows = slice_table_for_parallel_processing(sorted_spike_windows_for_current_tetrode,[]);

simple_channel_list = 1:numel(chan_of_art_tetrode);



for i=1:size(sorted_spike_windows_for_current_tetrode,1)

    current_window = sliced_spike_windows{i};
    % fprintf("current window: %i %i %i %i %i\n",current_window(1),current_window(2),current_window(3),current_window(4),current_window(5))

    if current_window(1,1) == current_window(1,2)
        continue;
    end

    if current_window(1,2) > current_window(1,1) && current_window(1,2) <length(timing_matrix)
        current_timing_slice = timing_matrix(current_window(1,1):min(current_window(1,2) -1,length(timing_matrix)));
        time_slices(i,:) = current_timing_slice;
    else
        disp("something went wrong")
    end
    for j=simple_channel_list
        if any(current_window>=length(timing_matrix),2)
            disp("something went wrong")
        end
        if current_window(1,2) > current_window(1,1) && current_window(1,2) < length(timing_matrix)
            spike_slices(j,i,:) = channels_data{j}(current_window(1,1) :min(current_window(1,2)-1,length(channels_data{j})));
        else
            disp("something went wrong")
        end
        
    end
    spiking_channels{i} = current_window(3);
end

end