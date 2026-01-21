function [spike_windows,overlap_of_unit_in_cluster_windows] = get_spike_windows_for_specific_channels(ordered_list_of_channels,fp_to_channels,desired_z_score,desired_number_of_data_points,ground_truth_spike_idxs,config)
%each array is made up of 5 numbers:
%the first is the beginning of the spike window
%the second is the end of the spike_window
%the third is the original channel of the spike
%the fourth is the original the peak of the spike according to find_peaks'
%the fifth is the z score of the peak of the spike according to find_peaks
%this version is used to determine the spike windows for the specified
%tetrode and channels
if ~config.use_new_spike_detection
    spike_windows_as_cell= cell(length(ordered_list_of_channels),1);
    for i=1:length(ordered_list_of_channels)

        current_channel = ordered_list_of_channels(i);

        %get the current channel waveform data
        current_channel_data = importdata(fullfile(fp_to_channels,current_channel));
        if config.use_bandpass
            current_channel_data = filt_car_(current_channel_data,config);
        end
        %get the z score data for the current channel
        channel_wise_z_score = zscore(current_channel_data);

        %get the spikes for the current window
        current_channel_data(abs(channel_wise_z_score) < desired_z_score) = 0;
        [~,spikes_for_current_channel] = findpeaks(current_channel_data);

        current_spike_windows = zeros(length(spikes_for_current_channel),5);
        for j=1:length(spikes_for_current_channel)
            channel_i_peak_j = spikes_for_current_channel(j); %get the current peak
            channel_i_peak_j_z_score = channel_wise_z_score(channel_i_peak_j); %get the z_score for current spike
            if channel_i_peak_j < fix(desired_number_of_data_points/2) || channel_i_peak_j+fix(desired_number_of_data_points/2) > length(channel_wise_z_score) %round towards zero
                %if peak is too early or too late don't use it
                current_spike_windows(j,:) = [0,0,0,0,0]; %zero is used as a flag since they should never be 0 as it is an invalid matlab index
            else
                if abs(channel_i_peak_j_z_score) >= desired_z_score
                    if channel_i_peak_j - fix(desired_number_of_data_points/2) ~= 0 && channel_i_peak_j + fix(desired_number_of_data_points/2) <= length(channel_wise_z_score)
                        current_spike_windows(j,:) = [channel_i_peak_j - fix(desired_number_of_data_points/2),...
                            channel_i_peak_j + fix(desired_number_of_data_points/2),...
                            i,...
                            channel_i_peak_j, ...
                            channel_i_peak_j_z_score];
                    else
                        current_spike_windows(j,:)=[0,0,0,0,0];
                    end
                    %each  is made up of 4 numbers:
                    %the first is the beginning of the spike window
                    %the second is the end of the spike_window
                    %the third is the original channel of the spike
                    %the fourth is the original the peak of the spike according to

                else
                    current_spike_windows(j,:) = [0,0,0,0,0];
                end
            end
        end
        spike_windows_as_cell{i} = current_spike_windows;
    end

    %remove any zero rows which were invalid or below the desired z score
    spike_windows = cell2mat(vertcat(spike_windows_as_cell));
    spike_windows(spike_windows(:,1)==0,:) = [];

    %turn it into a table so we can sort rows by peak location
    spike_windows_as_table = array2table(spike_windows);
    spike_windows_as_table = sortrows(spike_windows_as_table,4);

    %filter out any repeat rows
    spike_windows_as_table = unique(spike_windows_as_table,'rows');

    %finally get back to spike_windows
    spike_windows = table2array(spike_windows_as_table);
    

    %now use the ground truth how much of the desired unit is actually in the
    overlap_of_unit_in_cluster_windows = sum(ismembertol(double(ground_truth_spike_idxs),spike_windows(:,4),0.0001),"all") / length(ground_truth_spike_idxs);
else
    %if you aren't using the default spike detection then we'll use the one
    %that was taken from ironclust
    spike_windows_as_cell= cell(length(ordered_list_of_channels),1);
    for i=1:length(ordered_list_of_channels)

        current_channel = ordered_list_of_channels(i);

        %get the current channel waveform data
        current_channel_data = importdata(fullfile(fp_to_channels,current_channel));
        if config.use_bandpass
            current_channel_data = filt_car_(current_channel_data,config);
        end

        spike_windows_as_cell = spikeDetectSingle_fast_(current_channel_data);
    end

    spike_windows = vertcat(spike_windows_as_cell);


    %turn it into a table so we can sort rows by peak location
    spike_windows_as_table = array2table(spike_windows);
    spike_windows_as_table = sortrows(spike_windows_as_table);

    %filter out any repeat rows
    spike_windows_as_table = unique(spike_windows_as_table,'rows');

    %finally get back to spike_windows
    spike_windows = table2array(spike_windows_as_table);

    %now use the ground truth how much of the desired unit is actually in the
    overlap_of_unit_in_cluster_windows = sum(ismembertol(double(ground_truth_spike_idxs),spike_windows,0.0001),"all") / length(ground_truth_spike_idxs);

end
end