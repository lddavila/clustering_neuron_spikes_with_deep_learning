function [] = get_spike_windows_ver_3(channels,desired_z_score,lowest_bound_spike_windows_dir,new_spike_windows_dir,config)

%differs from get_spike_windows_ver_2 because instead of creating the spike windows array per channel
%this function reads an existing spike windows z score and eliminates any
%spikes that have a z score lower than the currently desired on
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(channels);
print_status_bar(num_iterations,"get_spike_windows_ver_3.m")

const_config = parallel.pool.Constant(config);
parfor i=1:length(channels)
    if isfile(fullfile(const_config.BLIND_PASS_DIR_PRECOMPUTED, "c"+string(channels(i))+".mat"))
        send(q,[]);
        continue;
    end
    current_channel = channels(i);
    previously_found_spike_windows = importdata(fullfile(lowest_bound_spike_windows_dir,"c"+string(current_channel)+".mat"));
    spike_windows = previously_found_spike_windows(previously_found_spike_windows(:,5)>=desired_z_score,:);
    par_save(fullfile(new_spike_windows_dir,"c"+string(current_channel)+".mat"),spike_windows)
    send(q,[]);
end



end