function [channel_wise_mean,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,dir_with_channel_data,z_score_dir, save_z_score,scale_factor,config)
% z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_z_score_files_to);
% disp("Created Z Score directory")
disp("Beginning get_channel_wise_statistics.m");
channel_wise_mean_unmapped = nan(1,size(ordered_list_of_channels,2));
channel_wise_std_unmapped = nan(1,size(ordered_list_of_channels,2));

channel_wise_mean = nan(1,config.max_channel_number);
channel_wise_std = nan(1,config.max_channel_number);

% status_log = fopen(config.FP_TO_STATUS_FILE,'a');
num_of_iterations = size(ordered_list_of_channels,2);

sliced_list_of_channels = num2cell(ordered_list_of_channels);
sliced_channel_numbers = str2double(strrep(ordered_list_of_channels,"c",""));

parfor i=1:size(ordered_list_of_channels,2)
    current_channel = sliced_list_of_channels{i};
    current_file = fullfile(dir_with_channel_data,current_channel+".mat");
    channel_data = importdata(current_file);
    channel_wise_mean_unmapped(i) = mean(channel_data*scale_factor);
    channel_wise_std_unmapped(i) = std(channel_data * scale_factor,0,"all"); %possible error in that I didn't multiply channel data by scale_factor when calculating std
                                                                    %have fixed it now, but definitely check new iterations to ensure that this doesn't suddenly destory everything
                                                                    %it should actually improve things if anything

    % status_message = "\n"+print_status_iter_message("get_channel_wise_statistics:calculate_mean_and_std",i,num_of_iterations);
    % fprintf(status_log,status_message);
                                                              

    if save_z_score
        channel_wise_z_score_data = zscore(channel_data * scale_factor);
        channel_wise_z_score_data = struct("channel_wize_z_score_data",channel_wise_z_score_data);
        save(fullfile(z_score_dir,current_channel+".mat"),"-fromstruct",channel_wise_z_score_data);
        % status_message = "\n"+print_status_iter_message("get_channel_wise_statistics:calculate_z_score_data",i,num_of_iterations);
        % fprintf(status_log,status_message);

    end
    % disp("Finished "+string(i) + "/"+string(length(ordered_list_of_channels)) )
end
for i=1:size(ordered_list_of_channels,2)
    channel_wise_mean(sliced_channel_numbers(i)) = channel_wise_mean_unmapped(i);
    channel_wise_std(sliced_channel_numbers(i)) = channel_wise_std_unmapped(i);
end
% fclose(status_log);
end