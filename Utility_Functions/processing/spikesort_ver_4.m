function [aligned, cleaned_clusters, timestamps,r_tvals,peak_pcs] = spikesort_ver_4(raw, timestamps, ir, tvals, config,channels,peak_pcs_file_name,full_config,varargin)
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
% disp("got into spikesort_ver_4.m")
wire_filter = find_live_wires(raw);

r_raw = single(raw(wire_filter, :, :));
r_ir = ir(wire_filter);
r_tvals = tvals(wire_filter);
if ~config.DEBUG
    clear raw ir tvals
end

num_spikes = size(r_raw, 2);
default_filter = true(num_spikes, 1); % Ignores no spikes
% Align spikes to peak, each wire independently
aligned = single(align_to_peak_ver_2(r_raw, r_tvals, r_ir));
% because of the data inflation that occurs when we try to save every
% aligned file we will instead add an optional parameter to this function
% that optional parameter is something called "base aligned idcs" which would be
% idx of the base aligned object created from the lowest multiplier used in
% the clustering process before any filters are applied (see
% run_spikesort_ntt_core_ver4.m to see exactly how this is gotten)
% because every subsequent aligned object ("local aligned") is just a subset of base aligned
% we can just index the base aligned instead of saving every aligned object
% to a file
% however a problem arises when we look at the idxs that tell us which
% spikes belong to which cluster.
% the cluster idxs are based on the local aligned data which are always a subset of base aligned data which means if we
% use them directly it will mis-index the clusters created by a higher
% multiplier
% so we need to translate the idxs from the "local aligned" object back to the "base aligned" object
% This way instead of saving mxn aligned files (m is how many multipliers
% are used and n is how many tetrodes are used) we only have to save m
% unfortunately this may be very costly because exactly matching the
% waveforms in local aligned to the waveforms in aligned can be very
% expensive as both can be in the size of tens or hundreds of thousands
if ~isempty(varargin)
    local_idxs = varargin{1}; %filters have already been applied to this so now the mask exists here and we get the alignment
end

% if sum(wire_filter) < 2 % Need at least live 2 wires.
%     cleaned_clusters = {};
%     grades = [];
%     return
% end

% Compute timestamp and SNR filters
if config.USE_TIMESTAMP_FILTER && length(timestamps) > 20000
    timestamp_filter = compute_timestamp_filter(timestamps);
else
    timestamp_filter = default_filter;
end
% disp("Finished getting timestamp filter")
full_config.mutated_spike_windows = full_config.mutated_spike_windows(timestamp_filter,:);
if full_config.has_ground_truth && full_config.debug_with_ground_truth
    full_config = check_unit_detection_while_clustering(full_config.mutated_spike_windows,full_config.tetrode,full_config,"aftertimestampfiltermult"+string(full_config.which_thresh),aligned,timestamp_filter);
    full_config.plot_counter = full_config.plot_counter+1;
    disp("Finished getting unit decetion while clustering 3")
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
    elseif full_config.use_percentile_for_pmv_filter
        only_positive = pmv(pmv>0);
        the_percentiles = prctile(only_positive,1:100);
        snr_threshs = the_percentiles(full_config.percentiles_to_use);
    else
        snr_threshs = full_config.the_linspace_to_use;
    end
    for k = 1:length(snr_threshs)
        snr_filter = pmv > snr_threshs(k);
        if full_config.debug_with_ground_truth

        end
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

% disp("Finished getting pmv and filtering data")
% Compute the whitening filter on the space of peaks
peaks = get_peaks(aligned, true)';
%a s by c array
%c: number of channels
%s: number of spikes
%each value in the array is the peak of channel c and spike s
% plot_peaks(peaks,"Peaks In Spikesort Ver 2", channels)

preproc_idx = cell(1, num_iterations);
preproc_spike_windows =cell(1, num_iterations);
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
    looped_mutated_spike_windows = full_config.mutated_spike_windows(combined_filter,:);
    % looped_mutated_spike_windows = looped_mutated_spike_windows(whiten_filter,:);
    
    if full_config.has_ground_truth && full_config.debug_with_ground_truth
        full_config = check_unit_detection_while_clustering(looped_mutated_spike_windows,full_config.tetrode,full_config,"wpzreworkedlinspace_"+string(k),aligned,combined_filter);
        full_config.plot_counter = full_config.plot_counter +1;
    end
    % disp("Finished getting unit decetion while clustering 4")
    % Injects our whitening filter into the original set of indices
    % since we applied the whitening after AFTER timestamp and SNR
    preproc_spike_windows{k} =looped_mutated_spike_windows ;
    preproc_idx{k} = combined_idx_inj(whiten_filter);
end

full_config.looped_mutated_sw = preproc_spike_windows;
% In the refinement step, use the spikes specified by this filter
refine_filter = timestamp_filter;
refine_spike_idx = find(refine_filter);

% Run multiple iterations of the cluster algorithm
%we are aware of an error where small amounts of data cause singular dimensions
%to do that
did_error = true; %assume that the function will error
while did_error && ~isempty(preproc_idx)
    % disp("entered the while loop")
    try
        [clusters,peak_pcs,full_config]= iterative_clustering_ver_2(aligned, r_ir, r_tvals, ...
            refine_spike_idx, preproc_idx, config,peak_pcs_file_name,full_config);
        did_error = false; %if it successfully completes we'll set did_error to false and continue to the rest of the algorithm
    catch ME
        preproc_idx = preproc_idx(2:end); %if the expected error occurs then to avoid completely dumping the algorithm we'll try again with a more liberal dataset
        config.NUM_ITERATIONS = length(preproc_idx); %update the number of iterations in the config
        ME.getReport;
        % disp("Adjusting data set ")
    end

end
if isempty(preproc_idx)
    cleaned_clusters = {};
    clusters = {};
    aligned = NaN;
    timestamps = NaN;
    r_tvals = NaN;
    peak_pcs = NaN;
    return;
end
%OG LINES RANGE FROM LINE 121-122
%  clusters = iterative_clustering(aligned, r_ir, r_tvals, ...
%     refine_spike_idx, preproc_idx, config);
% Optionally do PC1 cleaning afterward
if ~isempty(clusters) && config.USE_PC1_CLEANING
    cleaned_clusters = cell(size(clusters));
    pcs = get_new_pcs(aligned, true);
    pc1 = pcs(:,:,1)';
    for c = 1:length(clusters)
        cl_idx = clusters{c};
        cl = pc1(cl_idx, :);
        dim_filter = find_singular_cols(cl);

        %OG LINE: m = mahal(cl(:, dim_filter), cl(:, dim_filter));
        m = mahal_fixed_for_num_unstable(cl(:, dim_filter), cl(:, dim_filter));
        cl2_idx = cl_idx(m < median(m) + 2*std(m));
        cl2 = pc1(cl2_idx, :);
        dim_filter = find_singular_cols(cl2);
        %OG LINE:m2 = mahal(cl2(:, dim_filter), cl2(:, dim_filter));
        m2 = mahal_fixed_for_num_unstable(cl2(:, dim_filter), cl2(:, dim_filter));
        cleaned_clusters{c} = cl2_idx(m2 < median(m2) + 2*std(m2));
    end
elseif isempty(clusters)
    cleaned_clusters = {};
else
    cleaned_clusters = clusters;

end

%now actually map the new clusters to the local aligned
if ~isempty(varargin)
    new_cluster_idxs = cell(length(cleaned_clusters),1);
    for i=1:length(cleaned_clusters)
        new_cluster_idxs{i} = local_idxs(cleaned_clusters{i}); %gets you where the 
    end
    cleaned_clusters = new_cluster_idxs;
end

% Finally compute grades
%grades = compute_gradings_ver_2(aligned, timestamps, r_tvals, cleaned_clusters, config);
end