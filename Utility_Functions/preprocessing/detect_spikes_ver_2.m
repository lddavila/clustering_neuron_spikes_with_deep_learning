function [] = detect_spikes_ver_2(spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,dir_with_z_scores,min_z_score,scale_factor,config)

%if the 
if ~ismember(fullfile(spikes_per_channel_dir,"spikes_per_channel.mat"),config.ALREADY_DONE_FILES)
    spikes_matrix_unmapped = cell(1,size(ordered_list_of_channels,2));
    spikes_matrix = cell(1,config.max_channel_number);
    % status_file = fopen(config.FP_TO_STATUS_FILE,"a");
    q = parallel.pool.DataQueue;
    afterEach(q,@print_message_using_dataqueue)
    num_iterations = length(ordered_list_of_channels);
    print_message_using_dataqueue(num_iterations,"detect_spikes_ver_2.m")
    parfor i=1:length(ordered_list_of_channels)
        current_channel = ordered_list_of_channels(i);
        channel_data = importdata(fullfile(dir_with_channel_recordings,current_channel));
        channel_data = channel_data * scale_factor;
        z_score_data = importdata(fullfile(dir_with_z_scores,current_channel));
        if class(z_score_data) == "struct"
            z_score_data = z_score_data.channel_wize_z_score_data;
        end

        channel_data(abs(z_score_data) < min_z_score) = 0;

        [~,pk_locs] = findpeaks(channel_data);
        spikes_matrix_unmapped{i} = pk_locs;
        send(q,[]);
    end
    channels = strrep(ordered_list_of_channels,"c","");
    channels = strrep(channels,".mat","");
    for i=1:length(channels)
        spikes_matrix{str2double(channels(i))} = spikes_matrix_unmapped{i};
    end
    par_save(fullfile(spikes_per_channel_dir,"spikes_per_channel.mat"),spikes_matrix);
else
    disp("spikes_per_channel min_z_score "+ string(min_z_score)+ " has been detected and will be skipped.")
    disp("To recalculate delete the original or change your precomputed directory.")
end
end