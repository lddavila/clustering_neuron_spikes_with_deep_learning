function [spike_windows_fp] = get_spike_windows_ver_2(ordered_list_of_channels,fp_to_spikes_per_channel,desired_z_score,desired_number_of_data_points,dir_with_channel_z_scores,spike_windows_dir,config)
spike_windows_fp =fullfile(spike_windows_dir,"spike_windows.mat") ;
if ~ismember(fullfile(spike_windows_dir,"spike_windows.mat"),config.ALREADY_DONE_FILES)
    %each array is made up of 4 numbers:
    %the first is the beginning of the spike window
    %the second is the end of the spike_window
    %the third is the original channel of the spike
    %the fourth is the original the peak of the spike according to find_peaks'
    spike_windows_unmapped = cell(1,config.max_channel_number);
    number_of_iterations = length(ordered_list_of_channels);
    channel_numbers = strrep(ordered_list_of_channels,"c","");
    channel_numbers =strrep(channel_numbers,".mat","");
    channel_numbers = str2double(channel_numbers);
    % status_file = config.FP_TO_STATUS_FILE;
    q = parallel.pool.DataQueue;
    afterEach(q,@print_message_using_dataqueue)
    print_message_using_dataqueue(number_of_iterations,"get_spike_windows_ver_2.m")

    spikes_per_channel_as_mat_file = matfile(fp_to_spikes_per_channel);
    for i=1:length(ordered_list_of_channels)
        current_channel = ordered_list_of_channels(i);
        
        channel_wise_z_score = importdata(fullfile(dir_with_channel_z_scores,current_channel));
        tmp = spikes_per_channel_as_mat_file.data_to_save(1, channel_numbers(i));
        tmp = tmp{1};
        spike_windows_unmapped{i} = cell(length(tmp),1);
        for j=1:length(tmp)
            channel_i_peak_j = tmp(j); %get the current peak
            channel_i_peak_j_z_score = channel_wise_z_score(channel_i_peak_j); %get the z_score for current spike
            if channel_i_peak_j < fix(desired_number_of_data_points/2) || channel_i_peak_j+fix(desired_number_of_data_points/2) > length(channel_wise_z_score) %round towards zero
                %if peak is too early or too late don't use it
                spike_windows_unmapped{i}{j} = int32([0,0,0,0]); %zero is used as a flag since they should never be 0 as it is an invalid matlab index
            else
                if abs(channel_i_peak_j_z_score) >= desired_z_score
                    if channel_i_peak_j - fix(desired_number_of_data_points/2) ~= 0 && channel_i_peak_j + fix(desired_number_of_data_points/2) <= length(channel_wise_z_score)
                        spike_windows_unmapped{i}{j} = int32([channel_i_peak_j - fix(desired_number_of_data_points/2),...
                            channel_i_peak_j + fix(desired_number_of_data_points/2),...
                            i,...
                            channel_i_peak_j]);
                    else
                        spike_windows_unmapped{i}{j}=int32([0,0,0,0]);
                    end
                    %each  is made up of 4 numbers:
                    %the first is the beginning of the spike window
                    %the second is the end of the spike_window
                    %the third is the original channel of the spike
                    %the fourth is the original the peak of the spike according to

                else
                    spike_windows_unmapped{i}{j} = int32([0,0,0,0]);
                end
            end

        end
        send(q,[]);
    end

    spike_windows = cell(1,config.max_channel_number);
    for i=1:length(channel_numbers)
        spike_windows{channel_numbers(i)} = spike_windows_unmapped{i};
    end
    par_save(spike_windows_fp,spike_windows)
else
    disp(spike_windows_fp+" has been detected and will be skipped.")
    disp("To recalculate delete the original or change your precomputed directory.")
end


end