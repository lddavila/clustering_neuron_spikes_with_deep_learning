function [] = detect_spikes_ver_2(spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,dir_with_z_scores,min_z_score,scale_factor,config)
%if the file doesn't already exist then we must create and save it
q = parallel.pool.DataQueue;
afterEach(q,@print_message_using_dataqueue)
num_iterations = length(ordered_list_of_channels);
print_status_bar(num_iterations,"detect_spikes_ver_2.m")
already_done = config.ALREADY_DONE_FILES;
parfor i=1:length(ordered_list_of_channels)
    current_channel = ordered_list_of_channels(i);
    if ismember(fullfile(spikes_per_channel_dir,current_channel),already_done)
        send(q,[]);
        continue;
    end
    channel_data = importdata(fullfile(dir_with_channel_recordings,current_channel));
    channel_data = channel_data * scale_factor;
    z_score_data = importdata(fullfile(dir_with_z_scores,current_channel));
    if class(z_score_data) == "struct"
        z_score_data = z_score_data.channel_wize_z_score_data;
    end

    channel_data(abs(z_score_data) < min_z_score) = 0;

    [~,pk_locs] = findpeaks(channel_data);
    par_save(fullfile(spikes_per_channel_dir,current_channel),pk_locs);
    send(q,[]);
end
end