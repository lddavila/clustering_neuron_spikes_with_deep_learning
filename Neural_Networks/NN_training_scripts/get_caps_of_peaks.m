function [peak_caps] = get_caps_of_peaks(blind_pass_table,which_cap_string)
%extract the waveform you want the cap for
split_cap_string = split(which_cap_string," ");
which_waveform_string = "mean_waveform_rep_wire_"+split_cap_string(end);
mean_waveform_array = cell2mat(blind_pass_table{:,which_waveform_string});

%get the peak value of every cluster in the mean waveform
[peak_val,peak_idx] = max(mean_waveform_array,[],2);

%now get 10 dpts to the left of the peak and 10 to the right
peak_caps = mean_waveform_array(:,peak_idx-10:peak_idx+1);
end