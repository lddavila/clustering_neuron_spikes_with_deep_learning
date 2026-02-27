function [has_already_been_run] = check_if_current_data_has_already_been_run(max_peak_vals,which_channel,flat_multipliers,current_z_score,raw)
%the goal of this function is to see if this particular spike set has been
%in a previous iteration and thus should not be run again
all_spike_sizes_log = nan(size(flat_multipliers,2),1);
has_already_been_run = false;
for i=1:size(flat_multipliers,2)
    per_channel_thresholds_for_curr_z_sc= flat_multipliers(:,i);
    per_spike_thresholds = per_channel_thresholds_for_curr_z_sc(which_channel);
    new_raw = raw(:,max_peak_vals>=per_spike_thresholds,:);
    all_spike_sizes_log(i) = size(new_raw,2);
end
size_value = all_spike_sizes_log(current_z_score);
first_time_that_size_appears = find(all_spike_sizes_log==size_value,1);
if first_time_that_size_appears~=current_z_score
    has_already_been_run = true;
end

end