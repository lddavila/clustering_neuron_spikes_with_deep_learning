function [cell_array_of_thresh_in_mv,cell_array_of_pk_locs,cell_array_of_pk_vals] = use_ic_spike_det(spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,scale_factor,config,P_threshold)

%if the file doesn't already exist then we must create and save it
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(ordered_list_of_channels);
print_status_bar(num_iterations,"use_ic_spike_det.m")
cell_array_of_thresh_in_mv = repmat({nan(1,length(config.Multipliers))},config.max_channel_number,1);
cell_array_of_pk_locs = cell(length(ordered_list_of_channels),1);
cell_array_of_pk_vals = cell(length(ordered_list_of_channels),1);
channels_without_formatting = str2double(strrep(strrep(ordered_list_of_channels,"c",""),".mat",""));
parfor i=1:length(channels_without_formatting)
    current_channel = ordered_list_of_channels(i);
    if ~isfile(fullfile(spikes_per_channel_dir,current_channel))


        %disp(fullfile(dir_with_channel_recordings,current_channel))
        channel_data = importdata(fullfile(dir_with_channel_recordings,current_channel));
        channel_data = channel_data * scale_factor;
        P = struct('spkThresh', [], 'qqFactor', P_threshold);

        [pk_locs,pk_vals,channel_thresholds_in_mv]= spikeDetectSingle_fast_(channel_data,P);
        cell_array_of_thresh_in_mv{i} = channel_thresholds_in_mv;
        cell_array_of_pk_locs{i} = pk_locs;
        cell_array_of_pk_vals{i} = pk_vals;
        par_save(fullfile(spikes_per_channel_dir,strrep(current_channel,".mat","")),pk_locs);
        par_save(fullfile(spikes_per_channel_dir,strrep(current_channel,".mat","")+"_pk_amps.mat"),pk_vals);
        par_save(fullfile(spikes_per_channel_dir,strrep(current_channel,".mat","")+"_thresh_in_mv.mat"),channel_thresholds_in_mv);
    else
        cell_array_of_thresh_in_mv{i} = importdata(fullfile(spikes_per_channel_dir,strrep(current_channel,".mat","")+"_thresh_in_mv.mat"));
        cell_array_of_pk_locs{i} = importdata(fullfile(spikes_per_channel_dir,current_channel));
        cell_array_of_pk_vals{i} = importdata(fullfile(spikes_per_channel_dir,strrep(current_channel,".mat","")+"_pk_amps.mat"));
    end
    send(q,[]);
end
par_save(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mv_thresholds.mat"),cell_array_of_thresh_in_mv);

end
