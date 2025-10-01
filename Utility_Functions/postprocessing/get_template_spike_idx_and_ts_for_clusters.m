function [blind_pass_table] = get_template_spike_idx_and_ts_for_clusters(blind_pass_table)

sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,["Z Score","Tetrode"]);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(blind_pass_table,1);
print_status_bar(num_iterations,"get_template_spike_idx_and_ts_for_clusters.m")
for i=1:size(sliced_blind_pass_table,1)
    current_data = sliced_blind_pass_table{i};
    num_of_channels = size(current_data{:,"grades"}{1}{49},2);
    try
        aligned = importdata(current_data{1,"fp_to_aligned"});
        aligned = aligned.aligned;
    catch
        disp("Failed to load aligned file")
        disp(current_data{1,"fp_to_aligned"})
        send(q,[]);
        continue;
    end

    try
        load(current_data{1,"fp_to_cleaned_clusters"},"cleaned_clusters");
    catch
        disp("Failed to load cleaned clusters file")
        disp(current_data{1,"fp_to_cleaned_clusters"})
        send(q,[]);
        continue;
    end

    try
        timestamps = importdata(current_data{1,"fp_to_reg_timestamps_of_the_spikes"});
        timestamps = timestamps.reg_timestamps_of_the_spikes;
    catch
        disp("Failed to load timestamps of spikes");
        disp(current_data{1,"fp_to_reg_timestamps_of_spikes"});
        send(q,[]);
        continue;
    end

    disp("Faliure tetrode")
    disp(current_data{1,"Tetrode"})
    disp("Faliure z score");
    disp(current_data{1,"Z Score"})


    all_peaks = get_peaks(aligned, true);
    idx_cell_array = cell(size(current_data,1),1);
    mean_waveform_cell_array = cell(size(current_data,1),num_of_channels);
    timestamp_cell_array = cell(size(current_data,1),1);
    for j=10:length(cleaned_clusters)
        disp(j)
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