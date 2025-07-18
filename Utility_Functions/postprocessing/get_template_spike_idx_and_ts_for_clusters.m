function [blind_pass_table] = get_template_spike_idx_and_ts_for_clusters(blind_pass_table)
unique_aligned_fps = unique(blind_pass_table{:,"fp_to_aligned"});
number_of_iterations =size(unique_aligned_fps,1);

sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,["Z Score","Tetrode"]);

parfor i=1:size(sliced_blind_pass_table,1)
    current_data = sliced_blind_pass_table{i};

    try
        aligned = importdata(current_data{1,"fp_to_aligned"});
    catch
        disp("Failed to load aligned file")
        disp(current_data{1,"fp_to_aligned"})
        continue;
    end

    try
        output = importdata(current_data{1,"fp_to_output"});
    catch
        disp("Failed to load output file")
        disp(current_data{1,"fp_to_output"})
        continue;
    end

    try
        timestamps = importdata(current_data{1,"fp_to_reg_timestamps_of_the_spikes"});
    catch
        disp("Failed to load timestamps of spikes");
        disp(current_data{1,"fp_to_reg_timestamps_of_spikes"});
        continue;
    end

    idx_b4_filt = extract_clusters_from_output(output(:,1),output);

    all_peaks = get_peaks(aligned, true);
    idx_cell_array = cell(size(current_data,1),1);
    mean_waveform_cell_array = cell(size(current_data,1),1);
    timestamp_cell_array = cell(size(current_data,1),1);
    for j=1:length(idx_b4_filt)
        cluster_filter = idx_b4_filt{j};
        spikes = aligned(:, cluster_filter, :);
        peaks = all_peaks(:, cluster_filter);
        % Set up the representative wire for the cluster
        [~, max_wire] = max(peaks, [], 1);
        poss_wires = unique(max_wire);
        n = histc(max_wire, poss_wires);
        [~, max_n] = max(n);
        compare_wire = poss_wires(max_n);
        mean_waveform = mean(shiftdim(spikes(compare_wire, :, :), 1));
        mean_waveform = mean_waveform - mean(mean_waveform);
        mean_waveform_cell_array{j} = mean_waveform;
        idx_cell_array{j} = cluster_filter;
        timestamp_cell_array{j} = timestamps(cluster_filter);
    end
    current_data.("cluster_idx") = idx_cell_array;
    current_data.("Mean Waveform") = mean_waveform_cell_array;
    current_data.("timestamps") = timestamp_cell_array;
    disp("Finished "+string(i)+"/"+string(number_of_iterations))
    sliced_blind_pass_table{i} = current_data;
end
blind_pass_table = vertcat(sliced_blind_pass_table{:});
end