function [] = get_lowest_bound_spike_windows(ordered_list_of_channels,spikes_per_channel_dir,desired_z_score,desired_number_of_data_points,dir_with_channel_z_scores,spike_windows_dir,config)
%each array is made up of 5 numbers:
%the first is the beginning of the spike window
%the second is the end of the spike_window
%the third is the original channel of the spike
%the fourth is the original the peak of the spike according to find_peaks'
%the fifth is the z score of the peak of the spike according to find_peaks
number_of_iterations = length(ordered_list_of_channels);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(number_of_iterations,"get_lowest_bound_spike_windows.m")


already_done = config.ALREADY_DONE_FILES;
parfor i=1:length(ordered_list_of_channels)
    current_channel = ordered_list_of_channels(i);

    

    if ismember(fullfile(spike_windows_dir,current_channel),already_done)
        send(q,[])
        continue;
    end

    channel_wise_z_score = importdata(fullfile(dir_with_channel_z_scores,current_channel));
    spikes_for_current_channel = importdata(fullfile(spikes_per_channel_dir,current_channel));
    spike_windows = zeros(length(spikes_for_current_channel),5);
    for j=1:length(spikes_for_current_channel)
        channel_i_peak_j = spikes_for_current_channel(j); %get the current peak
        channel_i_peak_j_z_score = channel_wise_z_score(channel_i_peak_j); %get the z_score for current spike
        if channel_i_peak_j < fix(desired_number_of_data_points/2) || channel_i_peak_j+fix(desired_number_of_data_points/2) > length(channel_wise_z_score) %round towards zero
            %if peak is too early or too late don't use it
            spike_windows(j,:) = [0,0,0,0,0]; %zero is used as a flag since they should never be 0 as it is an invalid matlab index
        else
            if abs(channel_i_peak_j_z_score) >= desired_z_score
                if channel_i_peak_j - fix(desired_number_of_data_points/2) ~= 0 && channel_i_peak_j + fix(desired_number_of_data_points/2) <= length(channel_wise_z_score)
                    spike_windows(j,:) = [channel_i_peak_j - fix(desired_number_of_data_points/2),...
                        channel_i_peak_j + fix(desired_number_of_data_points/2),...
                        i,...
                        channel_i_peak_j, ...
                        channel_i_peak_j_z_score];
                else
                    spike_windows(j,:)=[0,0,0,0,0];
                end
                %each  is made up of 4 numbers:
                %the first is the beginning of the spike window
                %the second is the end of the spike_window
                %the third is the original channel of the spike
                %the fourth is the original the peak of the spike according to

            else
                spike_windows(j,:) = [0,0,0,0,0];
            end
        end
    end
    par_save(fullfile(spike_windows_dir,current_channel),spike_windows)
    send(q,[]);
end



end