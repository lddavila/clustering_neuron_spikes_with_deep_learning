function [blind_pass_table] = get_template_spike_idx_and_ts_for_clusters_kilosort4(blind_pass_table)

% ─────────────────────────────────────────────────────────────
% Add cluster-level waveform/timestamp/index data to blind pass
% table for downstream grading analysis.
% Compatible with Kilosort grading pipeline.
% ─────────────────────────────────────────────────────────────

q = parallel.pool.DataQueue;
num_iterations = size(blind_pass_table,1);

afterEach(q,@print_status_bar)
% print_status_bar(num_iterations,"add_cluster_waveform_data.m")

% Slice only by tetrode since no Z Score column exists
sliced_blind_pass_table = ...
    slice_table_for_parallel_processing( ...
        blind_pass_table, ...
        ["Tetrode"]);

for i = 1:size(sliced_blind_pass_table,1)

    current_data = sliced_blind_pass_table{i};

    % Number of channels from aligned data later
    num_of_channels = 4;

    % ── Load cleaned clusters ────────────────────────────────
    try



        cleaned_clusters_struct = current_data{1,"fp_to_cleaned_clusters"};
        
        cleaned_clusters_fp = cleaned_clusters_struct{1};

        cleaned_clusters = load(cleaned_clusters_fp);

    catch

        disp("Failed to load cleaned clusters file")
        disp(current_data{1,"fp_to_cleaned_clusters"})
        % send(q,[]);
        continue;

    end

    % ── Load aligned waveforms ───────────────────────────────
    try

        aligned_struct = current_data{1,"fp_to_aligned"};

        aligned_fp = aligned_struct{1};

        aligned = load(aligned_fp);
        aligned = struct2array(aligned);


    catch

        disp("Failed to load aligned file")
        disp(current_data{1,"fp_to_aligned"})
        % send(q,[]);
        continue;

    end

    % ── Load timestamps ──────────────────────────────────────
    try

        timestamps_struct = current_data{1,"fp_to_reg_timestamps_of_the_spikes"};

        timestamps_fp = timestamps_struct{1};

        timestamps = load(timestamps_fp);

    catch

        disp("Failed to load timestamps of spikes")
        disp(current_data{1,"fp_to_reg_timestamps_of_the_spikes"})
        % send(q,[]);
        continue;

    end

    % ── Compute peaks ────────────────────────────────────────
    all_peaks = get_peaks(aligned, true);

    idx_cell_array = cell(size(current_data,1),1);

    mean_waveform_cell_array = ...
        cell(size(current_data,1), num_of_channels);

    timestamp_cell_array = cell(size(current_data,1),1);

    cleaned_clusters = cleaned_clusters.cleaned_clusters;

    timestamps = timestamps.reg_timestamps_of_the_spikes;

    % ── Iterate through clusters ─────────────────────────────
    for j = 1:length(cleaned_clusters)


        cluster_filter = cleaned_clusters{j};

        spikes = aligned(:, cluster_filter, :);

        peaks = all_peaks(:, cluster_filter);

        % Representative wire hierarchy
        for k = 1:num_of_channels

            [~, max_wire] = max(peaks, [], 1);

            poss_wires = unique(max_wire);

            n = histc(max_wire, poss_wires);

            [~, max_n] = max(n);

            compare_wire = poss_wires(max_n);

            peaks(compare_wire,:) = nan;

            mean_waveform = mean( ...
                shiftdim( ...
                    spikes(compare_wire, :, :), ...
                    1));

            mean_waveform = ...
                mean_waveform - mean(mean_waveform);

            mean_waveform_cell_array{j,k} = mean_waveform * -1;

        end

        idx_cell_array{j} = cluster_filter;

        timestamp_cell_array{j} = timestamps{j};

    end

    % ── Add columns back to table ────────────────────────────
    current_data.("cluster_idx") = idx_cell_array;

    current_data.("timestamps") = timestamp_cell_array;

    for k = 1:num_of_channels

        current_data.( ...
            "mean_waveform_rep_wire_" + string(k)) = ...
            mean_waveform_cell_array(:,k);

    end

    sliced_blind_pass_table{i} = current_data;

    % send(q,[]);

end

% Recombine table
blind_pass_table = vertcat(sliced_blind_pass_table{:});

end