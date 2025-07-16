function [array_of_max_per_channel] = calculate_input_range_for_raw_by_channel_ver_3(channels_of_current_tetrode,dir_with_channel_recordings)
%raw is an array with the following dimensions
%1) Number of channels
%2) number of spikes
%3) number of data points
%to access all of the data points for the first channel, spike 1 you would index it as in the following example
%raw(1,1,:)

array_of_max_per_channel = length(channels_of_current_tetrode);
for i=1:length(channels_of_current_tetrode)
    current_channel = "c"+string(channels_of_current_tetrode(i));
    channel_data = importdata(fullfile(dir_with_channel_recordings,current_channel+".mat"));
    channel_data = channel_data * -1;
    [~,max_value] = bounds(abs(channel_data),"all"); %get the min/max value per channel
    array_of_max_per_channel(i) = max_value;
end
end