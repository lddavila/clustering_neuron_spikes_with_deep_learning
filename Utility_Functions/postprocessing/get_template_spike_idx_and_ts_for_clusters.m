function [blind_pass_table] = get_template_spike_idx_and_ts_for_clusters(blind_pass_table,config)
% blind_pass_table = update_fpths(blind_pass_table,spikesort_config);
if ~config.use_new_spike_detection
    sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,["Z Score","Tetrode"]);
else
    sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,["Multiplier","Tetrode"]);
end
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(blind_pass_table,1);
print_status_bar(num_iterations,"get_template_spike_idx_and_ts_for_clusters.m")
timestamps_array = importdata(config.TIMESTAMP_FP);
parfor i=1:size(sliced_blind_pass_table,1)
    current_data = sliced_blind_pass_table{i};
    num_of_channels = size(current_data{:,"grades"}{1}{49},2);

    try
        cleaned_clusters =load(current_data{1,"fp_to_cleaned_clusters"},"cleaned_clusters");
        cleaned_clusters = cleaned_clusters.cleaned_clusters;
    catch
        disp("Failed to load cleaned clusters file")
        disp(current_data{1,"fp_to_cleaned_clusters"})
        send(q,[]);
        continue;
    end
    try
        aligned_struct = load(aligned_fp,"data_to_save");
        aligned = aligned_struct.data_to_save;
    catch
        disp("Failed to load aligned file")
        disp(current_data{1,"fp_to_aligned"})
        send(q,[]);
        continue;
    end



    if config.use_new_spike_detection
        base_spike_windows_fp = fullfile(config.dictionaries_dir,current_tetrode + " sorted_spike_windows.mat");
        base_spike_windows_struct = load(base_spike_windows_fp,"data_to_save");
        base_spike_windows_dict = base_spike_windows_struct.data_to_save.sorted_spike_windows_for_current_tetrode_dictionary;
        the_dict_key = string(keys(base_spike_windows_dict));
        base_spike_windows = base_spike_windows_dict(the_dict_key);
        timestamps = timestamps_array(base_spike_windows(:,4));
    else
        try
            timestamps = importdata(current_data{1,"fp_to_reg_timestamps_of_the_spikes"});
            timestamps = timestamps.reg_timestamps_of_the_spikes;
        catch
            disp("Failed to load timestamps of spikes");
            disp(current_data{1,"fp_to_reg_timestamps_of_spikes"});
            send(q,[]);
            continue;
        end
    end

    % disp("Faliure tetrode")
    % disp(current_data{1,"Tetrode"})
    % disp("Faliure z score");
    % disp(current_data{1,"Z Score"})


    all_peaks = get_peaks(aligned, true);
    idx_cell_array = cell(size(current_data,1),1);
    mean_waveform_cell_array = cell(size(current_data,1),num_of_channels);
    timestamp_cell_array = cell(size(current_data,1),1);
    for j=1:length(cleaned_clusters)
        %disp(j)
        cluster_filter = cleaned_clusters{j};
        spikes = aligned(:, cluster_filter, :);
        peaks = all_peaks(:, cluster_filter);
        % Set up the representative wire for the cluster
        for k=1:num_of_channels
            % Set up the representative wire for the cluster
            [~, max_wire] = max(peaks, [], 1);
            poss_wires = unique(max_wire);
            n = histc(max_wire, poss_wires);
            [~, max_n] = max(n);
            compare_wire = poss_wires(max_n);
            peaks(compare_wire,:) = nan;
            mean_waveform = mean(shiftdim(spikes(compare_wire, :, :), 1));
            mean_waveform = mean_waveform - mean(mean_waveform);
            mean_waveform_cell_array{j,k} = mean_waveform;
        end
        idx_cell_array{j} = cluster_filter;
        timestamp_cell_array{j} = timestamps(cluster_filter);
    end
    current_data.("cluster_idx") = idx_cell_array;
    current_data.("timestamps") = timestamp_cell_array;
    for k=1:num_of_channels
        current_data.("mean_waveform_rep_wire_"+string(k)) = mean_waveform_cell_array(:,k);
    end
    sliced_blind_pass_table{i} = current_data;
    send(q,[]);
end
blind_pass_table = vertcat(sliced_blind_pass_table{:});
end