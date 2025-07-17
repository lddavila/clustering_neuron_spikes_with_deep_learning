function [spike_windows] = get_spike_windows_ver_2(ordered_list_of_channels,spikes_per_channel,desired_z_score,desired_number_of_data_points,dir_with_channel_z_scores,config)
spike_windows_unmapped = cell(1,config.max_channel_number);
number_of_iterations = size(ordered_list_of_channels,2);
channel_numbers = str2double(strrep(ordered_list_of_channels,"c",""));
% status_file = config.FP_TO_STATUS_FILE;
parfor i=1:size(ordered_list_of_channels,2)
    current_channel = ordered_list_of_channels(i);
    spike_windows_unmapped{i} = cell(size(spikes_per_channel,1),1);
    channel_wise_z_score = importdata(fullfile(dir_with_channel_z_scores,current_channel+".mat"));
    for j=1:size(spikes_per_channel{i},2)
        channel_i_peak_j = spikes_per_channel{i}(j); %get the current peak
        channel_i_peak_j_z_score = channel_wise_z_score(channel_i_peak_j); %get the z_score for current spike
        if channel_i_peak_j < fix(desired_number_of_data_points/2) || channel_i_peak_j+fix(desired_number_of_data_points/2) > size(channel_wise_z_score,2) %round towards zero
            %if peak is too early or too late don't use it
            spike_windows_unmapped{i}{j} = [NaN,NaN,NaN,NaN];
        else
            if abs(channel_i_peak_j_z_score) >= desired_z_score 
                if channel_i_peak_j - fix(desired_number_of_data_points/2) ~= 0 && channel_i_peak_j + fix(desired_number_of_data_points/2) <= size(channel_wise_z_score,2)
                    spike_windows_unmapped{i}{j} = [channel_i_peak_j - fix(desired_number_of_data_points/2),...
                        channel_i_peak_j + fix(desired_number_of_data_points/2),...
                        i,...
                        channel_i_peak_j];
                else
                    spike_windows_unmapped{i}{j}=[NaN,NaN,NaN,NaN];
                end
                %each  is made up of 4 numbers:
                %the first is the beginning of the spike window
                %the second is the end of the spike_window
                %the third is the original channel of the spike
                %the fourth is the original the peak of the spike according to 

            else
                spike_windows_unmapped{i}{j} = [NaN,NaN,NaN,NaN];
            end
        end
    end
    status_message = "\n"+print_status_iter_message("get_spike_windows_ver_2.m",i,number_of_iterations);
    % fprintf(status_file,status_message);

end

spike_windows = cell(1,config.max_channel_number);
for i=1:size(ordered_list_of_channels)
    spike_windows{channel_numbers(i)} = spike_windows_unmapped{i};
end
end