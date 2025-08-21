function [mean_waveform_array] = get_mean_waveform_from_table(blind_pass_table,which_waveform_string)
mean_waveform_array = cell2mat(blind_pass_table{:,which_waveform_string});
end