function [aligned, cleaned_clusters, grades] = spikesort(raw, timestamps, ir, tvals, config)
%SPIKESORT Performs the main spike sorting algorithm.
%   [aligned, new_cluster_filters, gradings] = SPIKESORT(raw, timestamps,
%   ir, tvals, config)
%
%   'raw' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It represents the raw spike samples recorded.
%
%   'timestamps' are the timestamps for each spike in microseconds.
%
%   'ir' are the input range values for each wire in microvolts.
%
%   'tvals' are the threshold values for each wire in microvolts.
%
%   'config' is the spikesort configuration struct.
%
%   'aligned' is an array of the aligned spikes (similar to 'raw').
%
%   'new_cluster_filters' is a cell array of indices for the clusters.
%
%   'gradings' is a n-by-k matrix, where n is the number of clusters, and k
%   is the number of grades.

    % Remove wires with no data.
    wire_filter = find_live_wires(raw);
    
    r_raw = raw(wire_filter, :, :);
    r_ir = ir(wire_filter);
    r_tvals = tvals(wire_filter);
    if ~config.DEBUG
        clear raw ir tvals
    end
    
    num_spikes = size(r_raw, 2);
    default_filter = true(num_spikes, 1); % Ignores no spikes
    
    % Align spikes to peak, each wire independently
    aligned = align_to_peak(r_raw, r_tvals, r_ir);
    
    if sum(wire_filter) < 2 % Need at least live 2 wires.
        cleaned_clusters = {};
        grades = [];
        return
    end
    
    % Compute timestamp and SNR filters
    if config.USE_TIMESTAMP_FILTER && length(timestamps) > 20000
        timestamp_filter = compute_timestamp_filter(timestamps);
    else
        timestamp_filter = default_filter;
    end
    
    num_iterations = max(config.NUM_ITERATIONS, 1);
    snr_filters = repmat(default_filter, [1, num_iterations]);
    
    if config.USE_SNR_FILTER && num_spikes > 10000
        good_filters = true(num_iterations, 1);
        pmv = compute_snr_statistic(aligned, r_raw, r_tvals, r_ir);
        if num_iterations == 2
            snr_threshs = 0;
        elseif num_iterations == 3
            snr_threshs = [1, 0];
        elseif num_iterations == 4
            snr_threshs = [1.5, 1, 0];
        else
            snr_threshs = linspace(2, 0, num_iterations-1);
        end
        for k = 1:length(snr_threshs)
            snr_filter = pmv > snr_threshs(k);
            num_filtered_spikes = sum(snr_filter);
            if num_filtered_spikes < 600
                good_filters(k) = false;
            else
                snr_filters(:, k) = snr_filter;
            end
        end
        snr_filters = snr_filters(:, good_filters);
        num_iterations = size(snr_filters, 2);
    end
    
    % Compute the whitening filter on the space of peaks
    peaks = get_peaks(aligned, true)';
    
    preproc_idx = cell(1, num_iterations);
    for k = 1:num_iterations
        snr_filter = snr_filters(:, k);
        combined_filter = snr_filter & timestamp_filter;
        % Store the indices so that we can use the vector as an injection
        % function back into the original set of indices
        combined_idx_inj = find(combined_filter);
        
        if config.USE_DENSITY_FILTER && ...
            (num_iterations == 1 || k < num_iterations)
            % Only apply density filter on the final iteration if there is
            % only one iteration to do.
            whiten_filter = whiten(peaks(combined_filter, :));
        else
            whiten_filter = true(size(combined_idx_inj));
        end
        % Injects our whitening filter into the original set of indices
        % since we applied the whitening after AFTER timestamp and SNR
        preproc_idx{k} = combined_idx_inj(whiten_filter);
    end
    
    % In the refinement step, use the spikes specified by this filter
    refine_filter = timestamp_filter;
    refine_spike_idx = find(refine_filter);
    
    % Run multiple iterations of the cluster algorithm
    clusters = iterative_clustering(aligned, r_ir, r_tvals, ...
        refine_spike_idx, preproc_idx, config);
    
    % Optionally do PC1 cleaning afterward
    if ~isempty(clusters) && config.USE_PC1_CLEANING
        cleaned_clusters = cell(size(clusters));
        pcs = get_new_pcs(aligned, true);
        pc1 = pcs(:,:,1)';
        for c = 1:length(clusters)
            cl_idx = clusters{c};
            cl = pc1(cl_idx, :);
            dim_filter = find_singular_cols(cl);
            m = mahal(cl(:, dim_filter), cl(:, dim_filter));
            cl2_idx = cl_idx(m < median(m) + 2*std(m));
            cl2 = pc1(cl2_idx, :);
            dim_filter = find_singular_cols(cl2);
            m2 = mahal(cl2(:, dim_filter), cl2(:, dim_filter));
            cleaned_clusters{c} = cl2_idx(m2 < median(m2) + 2*std(m2));
        end
    else
        cleaned_clusters = clusters;
    end
    
    % Finally compute grades
    grades = compute_gradings_ver_2(aligned, timestamps, r_tvals, cleaned_clusters, config);
end
