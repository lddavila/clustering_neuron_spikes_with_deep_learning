function [] = get_slices_per_artificial_tetrode_ver_2(chan_of_art_tetrode,spike_windows_dir,dir_with_chan_recordings,timing_matrix,number_of_dps_per_slice,scale_factor,tetrode_number,dict_fpths,min_z_score,config)

spike_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
spike_tetrode_dictionary_samples_format = containers.Map('KeyType','char','ValueType','any');
timing_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
spiking_channel_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
sorted_spike_windows_for_current_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
% peak_vals_dict = containers.Map('KeyType','char','ValueType','any');
% disp("Finished Creationg Dictionaries");
channels_data = cell(length(chan_of_art_tetrode),1);
for i=1:length(chan_of_art_tetrode)
    current_channel = chan_of_art_tetrode(i);
    % disp(fullfile(dir_with_chan_recordings,"c"+string(current_channel)+".mat"))
    current_channel_recording_file_name = fullfile(dir_with_chan_recordings,"c"+string(current_channel)+".mat");
    % disp("current channel recording file name")
    % disp(current_channel_recording_file_name);
    current_channel_data = load(current_channel_recording_file_name);
    the_field_name = string(fieldnames(current_channel_data));

    current_channel_data = current_channel_data.(the_field_name);
    current_channel_data = ( current_channel_data* scale_factor).';
    channels_data{i} = current_channel_data;
end

% disp("Finished importing data")

spike_windows = cell(length(chan_of_art_tetrode),1);
for i=1:length(spike_windows)
    current_channel = chan_of_art_tetrode(i);
    %disp(fullfile(spike_windows_dir,"c"+current_channel+".mat"))
    % disp("file that can't be loaded");
    % disp(fullfile(spike_windows_dir,"c"+current_channel+".mat"))
    current_spike_windows = load(fullfile(spike_windows_dir,"c"+current_channel+".mat"));
    current_spike_windows = current_spike_windows.data_to_save;
    spike_windows{i} = current_spike_windows;
end
% disp("Finsihed Getting Spike Windows")




spike_windows_for_current_tetrode =  vertcat(spike_windows{:});

if isempty(spike_windows_for_current_tetrode)
    return;
end

[sorted_spike_windows_for_current_tetrode,new_row_order] = sortrows(spike_windows_for_current_tetrode,[1,3]);
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
% disp("About to getting time and spike slices")
sliced_spike_windows = slice_table_for_parallel_processing(sorted_spike_windows_for_current_tetrode,[]);

simple_channel_list = 1:numel(chan_of_art_tetrode);

timing_matrix_const = parallel.pool.Constant(timing_matrix);
channels_data_const = parallel.pool.Constant(channels_data);
for i=1:size(sorted_spike_windows_for_current_tetrode,1)

    current_window = sliced_spike_windows{i};

    if current_window(1,1) == current_window(1,2) 
        continue;
    end

    current_timing_slice = timing_matrix_const.Value(current_window(1,1):current_window(1,2) -1);
    time_slices(i,:) = current_timing_slice;

    for j=simple_channel_list
        spike_slices(j,i,:) = channels_data_const.Value{j}(current_window(1,1) :current_window(1,2) -1);
        spike_slices_in_samples_format(:,j,i) = channels_data_const.Value{j}(current_window(1,1) :current_window(1,2)-1);
    end
    spiking_channels{i} = current_window(3);
end






% disp("Finished getting slices")
spike_tetrode_dictionary("t"+string(tetrode_number)) = spike_slices;
timing_tetrode_dictionary("t"+string(tetrode_number)) = time_slices;
spiking_channel_tetrode_dictionary("t"+string(tetrode_number)) = spiking_channels;
spike_tetrode_dictionary_samples_format("t"+string(tetrode_number)) = spike_slices_in_samples_format;
sorted_spike_windows_for_current_tetrode_dictionary("t"+string(tetrode_number)) = sorted_spike_windows_for_current_tetrode;
% peak_vals_dict("t"+string(tetrode_number)) = max(spike_slices,[],[1,3]).';
% disp("finished putting info into dictionaries")

spike_tetrode_dictionary = struct("spike_tetrode_dictionary",spike_tetrode_dictionary);
timing_tetrode_dictionary = struct("timing_tetrode_dictionary",timing_tetrode_dictionary);
spiking_channel_tetrode_dictionary = struct("spiking_channel_tetrode_dictionary",spiking_channel_tetrode_dictionary);
spike_tetrode_dictionary_samples_format = struct("spike_tetrode_dictionary_samples_format",spike_tetrode_dictionary_samples_format);
sorted_spike_windows_for_current_tetrode_dictionary = struct("sorted_spike_windows_for_current_tetrode_dictionary",sorted_spike_windows_for_current_tetrode_dictionary);
% disp("Finished getting structs")
% disp("Beginning Dictionary Saving")
par_save(dict_fpths(2),spike_tetrode_dictionary,false)
par_save(dict_fpths(3),timing_tetrode_dictionary,false)
par_save(dict_fpths(5),spiking_channel_tetrode_dictionary)
par_save(dict_fpths(6),spike_tetrode_dictionary_samples_format,false);
par_save(dict_fpths(7),sorted_spike_windows_for_current_tetrode_dictionary);
% par_save(dict_fpths(8),peak_vals_dict)
% disp("Finished Dictionary Saving")
end