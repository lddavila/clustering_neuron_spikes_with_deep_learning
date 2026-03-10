function [cell_array_of_thresh_in_mv] = use_ic_spike_det(spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,scale_factor,config,P_threshold)

%if the file doesn't already exist then we must create and save it
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(ordered_list_of_channels);
print_status_bar(num_iterations,"use_ic_spike_det.m")
already_done = config.ALREADY_DONE_FILES;
cell_array_of_thresh_in_mv = repmat({nan(1,length(config.Multipliers))},config.max_channel_number,1);
if ~isfile(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mv_thresholds.mat"))
    channels_without_formatting = str2double(strrep(strrep(ordered_list_of_channels,"c",""),".mat",""));
    for i=1:length(ordered_list_of_channels)
        current_channel = ordered_list_of_channels(i);
        channel_number = channels_without_formatting(i);
        if ismember(fullfile(spikes_per_channel_dir,current_channel),already_done)
            send(q,[]);
            continue;
        end
        %disp(fullfile(dir_with_channel_recordings,current_channel))
        channel_data = importdata(fullfile(dir_with_channel_recordings,current_channel));
        channel_data = channel_data * scale_factor;
        P = struct('spkThresh', [], 'qqFactor', P_threshold);
        
        [pk_locs,~,cell_array_of_thresh_in_mv{channel_number} ]= spikeDetectSingle_fast_(channel_data,P);
        par_save(fullfile(spikes_per_channel_dir,current_channel),pk_locs);
        send(q,[]);
    end
    par_save(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mv_thresholds.mat"),cell_array_of_thresh_in_mv);
else
    cell_array_of_thresh_in_mv = importdata(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mv_thresholds.mat"));
end
end
