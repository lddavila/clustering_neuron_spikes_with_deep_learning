function [] = get_spike_windows_ver_3(channels,desired_z_score,old_spike_windows_dir,new_spike_windows_dir)

%differs from get_spike_windows_ver_2 because instead of creating the spike windows array per channel
%this function reads an existing spike windows z score and eliminates any
%spikes that have a z score lower than the currently desired on

disp("entered get_spike_windows_ver_3")
disp("channels that were entered with")
disp(channels)
for i=1:length(channels)
    current_channel = channels(i);
    disp("file we're importing from")
    disp(fullfile(old_spike_windows_dir,current_channel))
    previously_found_spike_windows = importdata(fullfile(old_spike_windows_dir,current_channel));
    disp("Size of old spike windows")
    disp(size(previously_found_spike_windows));
    spike_windows = previously_found_spike_windows(previously_found_spike_windows(:,5)>=desired_z_score,:);
    disp("size of new spike windows");
    disp(size(spike_windows))
    disp("save path for spike windows")
    disp(fullfile(new_spike_windows_dir,current_channel),spike_windows)
    par_save(fullfile(new_spike_windows_dir,current_channel),spike_windows)
end
disp("Finished getting spike windows")


end