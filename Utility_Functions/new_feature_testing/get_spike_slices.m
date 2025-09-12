function [spike_slices] = get_spike_slices(chan_of_art_tetrode,spike_windows_dir,dir_with_chan_recordings,number_of_dps_per_slice,scale_factor,min_z_score)
channels_data = cell(length(chan_of_art_tetrode),1);
for i=1:length(chan_of_art_tetrode)
    current_channel = chan_of_art_tetrode(i);
    % disp(fullfile(dir_with_chan_recordings,"c"+string(current_channel)+".mat"))
    current_channel_recording_file_name = fullfile(dir_with_chan_recordings,"c"+string(current_channel)+".mat");
    channels_data{i} = (importdata(current_channel_recording_file_name) * scale_factor).';
end

spike_windows = cell(length(chan_of_art_tetrode),1);
for i=1:length(spike_windows)
    current_channel = chan_of_art_tetrode(i);
    %disp(fullfile(spike_windows_dir,"c"+current_channel+".mat"));
    spike_windows{i} = importdata(fullfile(spike_windows_dir,"c"+current_channel+".mat"));
end
% disp("Finsihed Getting Spike Windows")

spike_windows_for_current_tetrode =  vertcat(spike_windows{:});
spike_windows_for_current_tetrode(spike_windows_for_current_tetrode(:,5)<min_z_score,:)= []; %get rid of any spikes that don't meet the min z score

if isempty(spike_windows_for_current_tetrode)
    spike_slices = [];
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
spike_slices = zeros(size(chan_of_art_tetrode,2),size(sorted_spike_windows_for_current_tetrode,1),number_of_dps_per_slice);


spiking_channels = cell(1,size(sorted_spike_windows_for_current_tetrode,1));


if isempty(sorted_spike_windows_for_current_tetrode)
    return
end

sliced_spike_windows = slice_table_for_parallel_processing(sorted_spike_windows_for_current_tetrode,[]);

simple_channel_list = 1:numel(chan_of_art_tetrode);

for i=1:size(sorted_spike_windows_for_current_tetrode,1)
    current_window = sliced_spike_windows{i};
    if current_window(1,1) == current_window(1,2)
        continue;
    end

    for j=simple_channel_list
        spike_slices(j,i,:) = channels_data{j}(current_window(1,1) :current_window(1,2) -1);
    end
    spiking_channels{i} = current_window(3);

end

end