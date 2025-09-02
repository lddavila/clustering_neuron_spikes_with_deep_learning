function [channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,dir_with_channel_data,z_score_dir,scale_factor,config,what_is_computed)
% z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_z_score_files_to);
% disp("Created Z Score directory")
disp("Beginning get_channel_wise_statistics.m");
channel_wise_mean_unmapped = nan(1,size(ordered_list_of_channels,2));
channel_wise_std_unmapped = nan(1,size(ordered_list_of_channels,2));



% status_log = fopen(config.FP_TO_STATUS_FILE,'a');
num_iterations = size(ordered_list_of_channels,2);

sliced_list_of_channels = num2cell(ordered_list_of_channels);
ordered_list_of_channels = strrep(ordered_list_of_channels,".mat","");
sliced_channel_numbers = str2double(strrep(ordered_list_of_channels,"c",""));
q = parallel.pool.DataQueue;
afterEach(q,@print_message_using_dataqueue)
print_message_using_dataqueue(num_iterations,"get_channel_wise_statistics.m")
parfor i=1:length(ordered_list_of_channels)
    current_channel = sliced_list_of_channels{i};
    if ~ismember(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std","mean_and_std.mat"),what_is_computed) || ~exist(fullfile(z_score_dir,current_channel),"file")
        current_file = fullfile(dir_with_channel_data,current_channel);
        channel_data = importdata(current_file);
        channel_wise_mean_unmapped(i) = mean(channel_data*scale_factor);
        channel_wise_std_unmapped(i) = std(channel_data * scale_factor,0,"all"); %possible error in that I didn't multiply channel data by scale_factor when calculating std
        %have fixed it now, but definitely check new iterations to ensure that this doesn't suddenly destory everything
        %it should actually improve things if anything

        % status_message = "\n"+print_status_iter_message("get_channel_wise_statistics:calculate_mean_and_std",i,num_of_iterations);
        % fprintf(status_log,status_message);



        channel_wise_z_score_data = zscore(channel_data * scale_factor);
        par_save(fullfile(z_score_dir,current_channel),channel_wise_z_score_data);


    end
    % disp("Finished "+string(i) + "/"+string(length(ordered_list_of_channels)) )
end
if ~ismember(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std","mean_and_std.mat"),what_is_computed)
    create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std"));
    channel_wise_means = nan(1,config.max_channel_number);
    channel_wise_std = nan(1,config.max_channel_number);
    for i=1:length(ordered_list_of_channels)
        channel_wise_means(sliced_channel_numbers(i)) = channel_wise_mean_unmapped(i);
        channel_wise_std(sliced_channel_numbers(i)) = channel_wise_std_unmapped(i);
    end
    save(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std","mean_and_std.mat"),"channel_wise_means","channel_wise_std");
else
    disp("mean and Std file has been detected in your precomputed directory. If you'd like it recalculated then delete it or change your precomputed directory.")
    load(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std","mean_and_std.mat"),'channel_wise_means','channel_wise_std') %loads the previously found mean and std
end

end