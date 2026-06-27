function [cell_array_of_thresh_in_mv,cell_array_of_pk_locs,cell_array_of_pk_vals] = detect_spikes_ver_2(spikes_per_channel_dir,ordered_list_of_channels,dir_with_channel_recordings,dir_with_z_scores,min_z_score,scale_factor,config)
%if the file doesn't already exist then we must create and save it
thresh_in_mv_name = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"mv_thresholds.mat");
pk_locs_name = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"cell_array_of_peak_locations.mat");
pk_vals_name = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"cell_array_of_pk_amps.mat");

if ~all([isfile(thresh_in_mv_name),isfile(pk_locs_name),isfile(pk_vals_name)])
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = length(ordered_list_of_channels);
    print_status_bar(num_iterations,"detect_spikes_ver_2.m")
    cell_array_of_thresh_in_mv = repmat({nan(1,length(config.DEFAULT_CLUSTERING_Z_SCORES))},config.max_channel_number,1);
    cell_array_of_pk_locs = cell(length(ordered_list_of_channels),1);
    cell_array_of_pk_vals = cell(length(ordered_list_of_channels),1);
    
    parfor i=1:length(ordered_list_of_channels)
        current_channel = ordered_list_of_channels(i);
        save_name = fullfile(spikes_per_channel_dir,current_channel);
        if ~isfile(save_name)
            %disp(fullfile(dir_with_channel_recordings,current_channel))
            channel_data = importdata(fullfile(dir_with_channel_recordings,current_channel));
            channel_data = channel_data * scale_factor;
            z_score_data = importdata(fullfile(dir_with_z_scores,current_channel));
            if class(z_score_data) == "struct"
                z_score_data = z_score_data.channel_wize_z_score_data;
            end


            channel_data(abs(z_score_data) < min_z_score) = 0;
            z_score_in_mv = nan(1,length(config.DEFAULT_CLUSTERING_Z_SCORES));
            for j=1:length(config.DEFAULT_CLUSTERING_Z_SCORES)
                possible_val = abs(channel_data(find(abs(z_score_data)>=config.DEFAULT_CLUSTERING_Z_SCORES(j),1)));
                if ~isempty(possible_val)
                    z_score_in_mv(j) = possible_val;
                end
            end
            [pk_vals,pk_locs] = findpeaks(channel_data);
            pk_locs(pk_vals==0) = []; %weird artifact where a spike can have a peak value at 0 so this accounts for that check
            pk_vals(pk_vals==0) = [];

            cell_array_of_thresh_in_mv{i} = z_score_in_mv;
            cell_array_of_pk_locs{i} = pk_locs;
            cell_array_of_pk_vals{i} = pk_vals;
            par_save(fullfile(spikes_per_channel_dir,strrep(current_channel,".mat","")),pk_locs);
            par_save(fullfile(spikes_per_channel_dir,strrep(current_channel,".mat","")+"_pk_amps.mat"),pk_vals);
            par_save(fullfile(spikes_per_channel_dir,strrep(current_channel,".mat","")+"_thresh_in_mv.mat"),z_score_in_mv);
        else
            cell_array_of_thresh_in_mv{i} = load(fullfile(spikes_per_channel_dir,strrep(current_channel,".mat","")+"_thresh_in_mv.mat"));
            cell_array_of_thresh_in_mv{i} = cell_array_of_thresh_in_mv{i}.data_to_save;
            cell_array_of_pk_locs{i} = load(fullfile(spikes_per_channel_dir,current_channel));
            cell_array_of_pk_locs{i} = cell_array_of_pk_locs{i}.data_to_save;
            cell_array_of_pk_vals{i} = load(fullfile(spikes_per_channel_dir,strrep(current_channel,".mat","")+"_pk_amps.mat"));
            cell_array_of_pk_vals{i} = cell_array_of_pk_vals{i}.data_to_save;
        end
        send(q,[]);
    end
    par_save(thresh_in_mv_name,cell_array_of_thresh_in_mv);
    par_save(pk_locs_name,cell_array_of_pk_locs)
    par_save(pk_vals_name,cell_array_of_pk_vals)
else
    cell_array_of_thresh_in_mv = load(thresh_in_mv_name).data_to_save;
    cell_array_of_pk_locs = load(pk_locs_name).data_to_save;
    cell_array_of_pk_vals = load(pk_vals_name).data_to_save;
end
end