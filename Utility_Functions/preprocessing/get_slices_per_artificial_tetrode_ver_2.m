function [spike_slices,time_slices,spiking_channels,spike_slices_in_samples_format,sorted_spike_windows_for_current_tetrode] = get_slices_per_artificial_tetrode_ver_2(chan_of_art_tetrode,spike_windows_fp,dir_with_chan_recordings,timing_matrix,number_of_dps_per_slice,scale_factor)

channels_data = cell(1,length(chan_of_art_tetrode));
spike_windows_per_channel_as_mat_file = matfile(spike_windows_fp);
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


spike_windows = cell(length(chan_of_art_tetrode),1);
for i=1:length(spike_windows)
    current_channel = chan_of_art_tetrode(i);
    tmp = spike_windows_per_channel_as_mat_file.data_to_save(1,current_channel);
    spike_windows{i} = tmp{1};
end

spike_windows_for_current_tetrode =  cell2mat(vertcat(spike_windows{:}));

if isempty(spike_windows_for_current_tetrode)
    return;
end

sorted_spike_windows_for_current_tetrode = sortrows(spike_windows_for_current_tetrode,[1,3]);
sorted_spike_windows_for_current_tetrode(any(sorted_spike_windows_for_current_tetrode==0,2),:) = []; %any rows that have a zero must be removed
                                                                                                    %this is because zero is an invalid index and indicates something went wrong

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