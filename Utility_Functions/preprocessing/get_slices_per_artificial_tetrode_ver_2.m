function [spike_slices,time_slices,spiking_channels,spike_slices_in_samples_format,sorted_spike_windows_for_current_tetrode] = get_slices_per_artificial_tetrode_ver_2(chan_of_art_tetrode,spike_windows,dir_with_chan_recordings,timing_matrix,number_of_dps_per_slice,scale_factor)

channels_data = cell(1,length(chan_of_art_tetrode));
for i=1:length(chan_of_art_tetrode)
    current_channel = chan_of_art_tetrode(i);
    % disp(fullfile(dir_with_chan_recordings,"c"+string(current_channel)+".mat"))
    current_channel_recording_file_name = fullfile(dir_with_chan_recordings,"c"+string(current_channel)+".mat");
    channels_data{i} = importdata(current_channel_recording_file_name);
    channels_data{i} = channels_data{i} * scale_factor;
end

spike_slices = {};
time_slices = {};
spiking_channels = {};
spike_slices_in_samples_format = {};

%spike_windows_for_current_tetrode = [];
number_of_rows_required = 0;
number_of_cols_required = length(chan_of_art_tetrode);
number_of_spikes_per_channel = zeros(1,length(chan_of_art_tetrode));
for i=1:length(chan_of_art_tetrode)
    current_channel = chan_of_art_tetrode(i);
    number_of_rows_required = number_of_rows_required+size(spike_windows{current_channel},2);
    number_of_spikes_per_channel(i) = size(spike_windows{current_channel},2);
end
spike_windows_for_current_tetrode = zeros(number_of_rows_required,number_of_cols_required);

for i=1:length(chan_of_art_tetrode)
    current_channel = chan_of_art_tetrode(i);
    spike_windows_for_current_channel = zeros(size(spike_windows{current_channel},2),size(chan_of_art_tetrode,2));
    for j=1:size(spike_windows{current_channel},2)
        if isempty(spike_windows_for_current_channel)
            continue;
        end
        if isempty(spike_windows{current_channel}{j})
            continue;
        end
        spike_windows_for_current_channel(j,1) = spike_windows{current_channel}{j}(1);
        spike_windows_for_current_channel(j,2) = spike_windows{current_channel}{j}(2);
        spike_windows_for_current_channel(j,3) = spike_windows{current_channel}{j}(3);
        spike_windows_for_current_channel(j,4) = spike_windows{current_channel}{j}(4);
    end
    if isempty(spike_windows_for_current_channel)
        continue;
    end
    if i==1
        spike_windows_for_current_tetrode(1:number_of_spikes_per_channel(i),:) = spike_windows_for_current_channel;
    else
        spike_windows_for_current_tetrode(sum(number_of_spikes_per_channel(1:i-1))+1:sum(number_of_spikes_per_channel(1:i)),:) = spike_windows_for_current_channel;
    end
end

if isempty(spike_windows_for_current_tetrode)
    return;
end
sorted_spike_windows_for_current_tetrode = sortrows(spike_windows_for_current_tetrode,[1,3]);
sorted_spike_windows_for_current_tetrode = rmmissing(sorted_spike_windows_for_current_tetrode);

%spike_slices: must be sorted in such a way that when you run the following code the output matches
%[numwires, numspikes, numdp] = size(raw);
%numwires: number of channels
%numspikes: number of spikes
%numdp: number of datapoints

%
spike_slices = zeros(size(chan_of_art_tetrode,2),size(sorted_spike_windows_for_current_tetrode,1),number_of_dps_per_slice);

%spike_slices_in_samples_format is the same data as in spike_slices, but permutted differently
%   Samples: spike waveform samples formatted as a 32xMxN matrix of data
%       points, where M is the number of subchannels (wires) in the spike
%       file (NTT M = 4, NST M = 2, NSE M = 1). These values are in AD
%       counts.
spike_slices_in_samples_format =zeros(number_of_dps_per_slice,size(chan_of_art_tetrode,2),size(sorted_spike_windows_for_current_tetrode,1));

time_slices = zeros(size(sorted_spike_windows_for_current_tetrode,1),number_of_dps_per_slice);
spiking_channels = cell(1,size(sorted_spike_windows_for_current_tetrode,1));
for i=1:size(sorted_spike_windows_for_current_tetrode,1)
    if size(sorted_spike_windows_for_current_tetrode,2) == 0
        break;
    end

    current_window = sorted_spike_windows_for_current_tetrode(i,:);
    window_beginning = current_window(1);
    window_end = current_window(2);


    if window_beginning == window_end || length(timing_matrix(window_beginning:window_end-1)) <10
        continue;
    end
    
    current_timing_slice = timing_matrix(window_beginning:window_end-1);
    time_slices(i,:) = current_timing_slice;
    
    for j=1:length(chan_of_art_tetrode)
        spike_slices(j,i,:) = channels_data{j}(window_beginning:window_end-1);
        spike_slices_in_samples_format(:,j,i) = channels_data{j}(window_beginning:window_end-1);
    end
    spiking_channels{i} = current_window(3);
end
end