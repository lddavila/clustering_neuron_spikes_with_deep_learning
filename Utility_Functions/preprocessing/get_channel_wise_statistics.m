function [channel_wise_means,channel_wise_std] = get_channel_wise_statistics(ordered_list_of_channels,dir_with_channel_data,z_score_dir,scale_factor,config,what_is_computed)
% z_score_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_z_score_files_to);
% disp("Created Z Score directory")
disp("Beginning get_channel_wise_statistics.m");
channel_wise_mean_unmapped = nan(1,size(ordered_list_of_channels,2));
channel_wise_std_unmapped = nan(1,size(ordered_list_of_channels,2));
num_iterations = length(ordered_list_of_channels);

sliced_list_of_channels = num2cell(ordered_list_of_channels);
ordered_list_of_channels = strrep(ordered_list_of_channels,".mat","");
sliced_channel_numbers = str2double(strrep(ordered_list_of_channels,"c",""));

%if there's not already an existing mean and std we need to calculate it
if ~ismember(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std","mean_and_std.mat"),what_is_computed)
    create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std"));
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    print_status_bar(num_iterations,"get_channel_wise_statistics.m")
    using_binary = config.USING_BINARY_FILES;
    if ~using_binary
        parfor i=1:length(ordered_list_of_channels)
            current_channel = sliced_list_of_channels{i};
            if ~exist(fullfile(z_score_dir,current_channel+".mat"),"file")
                current_file = fullfile(dir_with_channel_data,current_channel);
                channel_data = importdata(current_file);
                [channel_wise_z_score_data,channel_wise_mean_unmapped(i),channel_wise_std_unmapped(i)] = zscore(single(channel_data) * single(scale_factor));
                par_save(fullfile(z_score_dir,current_channel),channel_wise_z_score_data);
            end
            send(q,[]);
        end
    else
        for i=1:length(ordered_list_of_channels)
            current_channel = sliced_list_of_channels{i};
            channel_data = read_channel_data_from_binary_file(dir_with_channel_data,current_channel);
        end
    end
    channel_wise_means = nan(1,config.max_channel_number);
    channel_wise_std = nan(1,config.max_channel_number);
    for i=1:length(ordered_list_of_channels)
        channel_wise_means(sliced_channel_numbers(i)) = channel_wise_mean_unmapped(i);
        channel_wise_std(sliced_channel_numbers(i)) = channel_wise_std_unmapped(i);
    end
    save(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std","mean_and_std.mat"),"channel_wise_means","channel_wise_std");
else
    %if it does already exist then we load it
    disp("mean and Std file has been detected in your precomputed directory. If you'd like it recalculated then delete it or change your precomputed directory.")
    load(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mean_and_std","mean_and_std.mat"),'channel_wise_means','channel_wise_std') %loads the previously found mean and std
end

end