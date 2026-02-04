function [thresh_mv] = use_ic_spike_det(spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,scale_factor,config,P_threshold)

%if the file doesn't already exist then we must create and save it
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(ordered_list_of_channels);
print_status_bar(num_iterations,"use_ic_spike_det.m")
already_done = config.ALREADY_DONE_FILES;
for i=1:length(ordered_list_of_channels)
    current_channel = ordered_list_of_channels(i);
    if ismember(fullfile(spikes_per_channel_dir,current_channel),already_done)
        send(q,[]);
        continue;
    end
    %disp(fullfile(dir_with_channel_recordings,current_channel))
    channel_data = importdata(fullfile(dir_with_channel_recordings,current_channel));
    channel_data = channel_data * scale_factor;
    P = struct('spkThresh', [], 'qqFactor', P_threshold);
    [pk_locs,~,thresh_mv ]= spikeDetectSingle_fast_(channel_data,P);
    par_save(fullfile(spikes_per_channel_dir,current_channel),pk_locs);
    send(q,[]);
end
end
