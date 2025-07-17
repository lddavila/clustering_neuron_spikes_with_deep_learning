function [spikes_matrix] = detect_spikes_ver_2(ordered_list_of_channels,dir_with_channel_recordings,dir_with_z_scores,min_z_score,scale_factor,config)
spikes_matrix_unmapped = cell(1,size(ordered_list_of_channels,2));
spikes_matrix = cell(1,config.max_channel_number);
num_iterations = size(ordered_list_of_channels,2);
% status_file = fopen(config.FP_TO_STATUS_FILE,"a");
parfor i=1:length(ordered_list_of_channels)
    current_channel = ordered_list_of_channels(i);
    channel_data = importdata(fullfile(dir_with_channel_recordings,current_channel+".mat"));
    channel_data = channel_data * scale_factor;
    z_score_data = importdata(fullfile(dir_with_z_scores,current_channel+".mat"));

    channel_data(abs(z_score_data) < min_z_score) = 0;

    [~,pk_locs] = findpeaks(channel_data);
    spikes_matrix_unmapped{i} = pk_locs;
end
for i=1:size(ordered_list_of_channels,2)
    spikes_matrix{str2double(strrep(ordered_list_of_channels(i),"c",""))} = spikes_matrix_unmapped{i};
end
status_message = "\n"+print_status_iter_message("detect_spikes_ver_2.m",i,num_iterations);
% fprintf(status_file,status_message);
% fclose(status_file);
end