function [] = get_slices_per_artificial_tetrode_ver_2(chan_of_art_tetrode,spike_windows_fp,dir_with_chan_recordings,timing_matrix,number_of_dps_per_slice,scale_factor,tetrode_number,dict_fpths)

spike_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
spike_tetrode_dictionary_samples_format = containers.Map('KeyType','char','ValueType','any');
timing_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
spiking_channel_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
sorted_spike_windows_for_current_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');

channels_data = cell(1,length(chan_of_art_tetrode));
spike_windows_per_channel_as_mat_file = matfile(spike_windows_fp);
for i=1:length(chan_of_art_tetrode)
    current_channel = chan_of_art_tetrode(i);
    % disp(fullfile(dir_with_chan_recordings,"c"+string(current_channel)+".mat"))
    current_channel_recording_file_name = fullfile(dir_with_chan_recordings,"c"+string(current_channel)+".mat");
    channels_data{i} = importdata(current_channel_recording_file_name);
    channels_data{i} = channels_data{i} * scale_factor;
end
channels_data = cell2mat(vertcat(channels_data{:}));


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


if isempty(sorted_spike_windows_for_current_tetrode)
    return
end

for i=1:size(sorted_spike_windows_for_current_tetrode,1)
    current_window = sorted_spike_windows_for_current_tetrode(i,:);

    if sorted_spike_windows_for_current_tetrode(i,1) == sorted_spike_windows_for_current_tetrode(i,2)
        continue;
    end

    current_timing_slice = timing_matrix(sorted_spike_windows_for_current_tetrode(i,1):sorted_spike_windows_for_current_tetrode(i,2) -1);
    time_slices(i,:) = current_timing_slice;

    for j=1:length(chan_of_art_tetrode)
        spike_slices(j,i,:) = channels_data{j}(sorted_spike_windows_for_current_tetrode(i,1) :sorted_spike_windows_for_current_tetrode(i,2) -1);
        spike_slices_in_samples_format(:,j,i) = channels_data{j}(sorted_spike_windows_for_current_tetrode(i,1) :sorted_spike_windows_for_current_tetrode(i,2)-1);
    end
    spiking_channels{i} = current_window(3);
    if mod(i,1000)
        print_status_iter_message("get_slices_per_artificial_tetrode_ver_2.m",i,size(sorted_spike_windows_for_current_tetrode,1));
    end
end
spike_tetrode_dictionary("t"+string(tetrode_number)) = spike_slices;
timing_tetrode_dictionary("t"+string(tetrode_number)) = time_slices;
spiking_channel_tetrode_dictionary("t"+string(tetrode_number)) = spiking_channels;
spike_tetrode_dictionary_samples_format("t"+string(tetrode_number)) = spike_slices_in_samples_format;
sorted_spike_windows_for_current_tetrode_dictionary("t"+string(tetrode_number)) = sorted_spike_windows_for_current_tetrode;

spike_tetrode_dictionary = struct("spike_tetrode_dictionary",spike_tetrode_dictionary);
timing_tetrode_dictionary = struct("timing_tetrode_dictionary",timing_tetrode_dictionary);
spiking_channel_tetrode_dictionary = struct("spiking_channel_tetrode_dictionary",spiking_channel_tetrode_dictionary);
spike_tetrode_dictionary_samples_format = struct("spike_tetrode_dictionary_samples_format",spike_tetrode_dictionary_samples_format);
sorted_spike_windows_for_current_tetrode_dictionary = struct("sorted_spike_windows_for_current_tetrode_dictionary",sorted_spike_windows_for_current_tetrode_dictionary);

par_save(dict_fpths(2),spike_tetrode_dictionary)
par_save(dict_fpths(3),timing_tetrode_dictionary)
par_save(dict_fpths(5),spiking_channel_tetrode_dictionary)
par_save(dict_fpths(6),spike_tetrode_dictionary_samples_format);
par_save(dict_fpths(7),sorted_spike_windows_for_current_tetrode_dictionary);
end