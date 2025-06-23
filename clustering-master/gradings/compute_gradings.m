function grades = compute_gradings(aligned, timestamps, tvals, clusters, config)
%COMPUTE_GRADINGS Computes grades for each of the clusters.
%   grades = COMPUTE_GRADINGS(aligned, timestamps, tvals, clusters) returns
%   the grades for each of the clusters.
%
%   'aligned' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It is the same as 'raw', but with spikes aligned to have the same peak
%   index.
%
%   'timestamps' are the timestamps for each spike in microseconds.
%   
%   'tvals' are the threshold values for each wire in microvolts.
%
%   'clusters' is a cell array of indices for each of the clusters.
%
%   The grades are:
%   1) LRatio(useless) - a measure of isolation of the cluster from the rest of the
%   spikes
%   2) Tightness - a measure of how tight the waveforms are using peaks
%   3) Percent short ISIs - a measure of how much of the cluster has short
        %most neurons don't fire close
        %ISI is interspike interval (distance between spikes
            %small ISI's are very rare, a lot of them could indicate bad clusters
            %interspike intervals (less than 3ms)
%   4) Incompleteness - a measure of how much of the cluster was cut off by the threshold
        %if the threshol is set incorrectly then you won't have smooth round edges to the cluster, instead you'll have sharp cuts
        %sometimes this is necessary because expanding in every dimension isn't possible as it will sometimes overlap with other clusters / destroy your shape
%   5) Isolation Distance (useless) - a measure of how far a cluster is from the threshold
        %Similar to LRato and Bhaat distance, like distance for the thresholds
        %the more distant from the threshold the better the grade
        %might not be great because it depends on the thresholds which can change quite a bit

%   6) The number of spikes
        %too many spikes is suspicious
        %too few spikes might also indicate noise
%   7) Stationarity in time (lack thereof) reporting
        %if a cluster's voltage is drifting
        %
%   8) Template matching of the representative wire's mean waveform
        %similarity across channels
        %compare with channels with biggest amplitude
        %might be good for creating better tetrode configurations
        %take a template from the highest spiking channel and compare it to the other channels in the tetrode 
        %calculate mean waveform of each cluster and then check the variance between the actual spikes 
%   9) Bhattacharyya Distance to every cluster (going to be replaced with bhaat distance of correct dimensions) 
%   10) Bhattacharyya Distance to unsorted spikes (useless because we simply have too many spikes for this to be useful)

    num_clusters = length(clusters);
    grades = nan(num_clusters, 27);
    total_raw_spikes = 1:size(aligned, 2);
    all_peaks = get_peaks(aligned, true);
    temp = load('template.mat');
    for k = 1:num_clusters
        % Set up cluster-specific vars
        cluster_filter = clusters{k};
        ts = timestamps(cluster_filter);
        spikes = aligned(:, cluster_filter, :);
        peaks = all_peaks(:, cluster_filter);
        
        % Set up the representative wire for the clusterd
        [~, max_wire] = max(peaks, [], 1);
        poss_wires = unique(max_wire);
        n = histc(max_wire, poss_wires);
        [~, max_n] = max(n);
        compare_wire = poss_wires(max_n);
        wire_thresh = tvals(compare_wire);
        compare_peaks = peaks(compare_wire, :);
        
        % Rate how good the cluster is based on how far away it is from the
        % rest of the spikes (including unclustered).
        other_good_spikes = setdiff(total_raw_spikes, cluster_filter);
        other_peaks = all_peaks(:, other_good_spikes);
        data_filt = find_singular_cols(other_peaks');
        lratio = compute_lratio(peaks(data_filt, :)', other_peaks(data_filt, :)');
        grades(k, 1) = lratio;
        
        % Peak cv check
        cv = compute_cv(peaks);
        grades(k, 2) = cv;
        
        % ISI check
        isi = diff(ts) * 1e-6; % Convert to seconds
        short_isi_len = config.params.GR_SHORT_ISI_LEN;
        short_isi = sum(isi < short_isi_len)/length(isi); % Fraction of ISI < short_isi_len
        grades(k, 3) = short_isi;
        
        % Theoretical fraction below threshold
        below_threshold = compute_incompleteness(compare_peaks, wire_thresh);
        grades(k, 4) = below_threshold;
        
        % Isolation distance
        grades(k, 5) = mahal(double(wire_thresh), compare_peaks');
        
        % Number of spikes
        grades(k, 6) = length(cluster_filter);
        
        % Stationarity
        t_mu = mean(timestamps);
        t_std = std(timestamps);
        cluster_med = median(timestamps(cluster_filter));
        grades(k, 7) = cluster_med < t_mu - t_std || cluster_med > t_mu + t_std;
        
        % Template matching
        if length(cluster_filter) > 1
            mean_waveform = mean(shiftdim(spikes(compare_wire, :, :), 1));
            mean_waveform = mean_waveform - mean(mean_waveform);
            grades(k, 8) = template_match(mean_waveform, temp.nt);
        else
            grades(k, 8) = 0;
        end
        
        % Bhat distance
        dists = inf(num_clusters, 1);
        peaks = peaks';
        for c = 1:num_clusters
            if c == k
                continue
            end
            other_cf = clusters{c};
            other_peaks = all_peaks(:, other_cf)';
            dim_filt = find_singular_cols(peaks) & find_singular_cols(other_peaks);
            if any(dim_filt)
                dists(c) = bhat_dist(peaks(:, dim_filt), other_peaks(:, dim_filt));
            end
        end
        min_bhat = min(dists);
        grades(k, 9) = min_bhat;
        
        % Bhat distance to unsorted
        other_cf = setdiff(1:size(all_peaks, 2), unique(vertcat(clusters{:})));
        other_peaks = all_peaks(:, other_cf)';
        dim_filt = find_singular_cols(peaks) & find_singular_cols(other_peaks);
        if ~isempty(other_peaks) && any(dim_filt)
            grades(k, 10) = bhat_dist(peaks(:, dim_filt), other_peaks(:, dim_filt));
        end
        
        grades(k, 11) = compute_lratio(peaks(:, dim_filt), other_peaks(:, dim_filt));
        
        rep_wire = shiftdim(spikes(compare_wire, :, :), 1);
        [~, snr] = compute_new_cv(rep_wire, 0.5);
        grades(k, 16) = snr;
        [~, snr] = compute_new_cv(rep_wire, 0.33);
        grades(k, 17) = snr;
        [~, snr] = compute_new_cv(rep_wire, 0.25);
        grades(k, 18) = snr;
        grades(k, 12) = compute_new_cv(rep_wire, 0.5);
        grades(k, 13) = compute_new_cv(rep_wire, 0.33);
        grades(k, 14) = compute_new_cv(rep_wire, 0.25);
        
        isi = isi * 1e3; % milliseconds
        grades(k, 15) = sum(isi < 7.5) / sum(isi < 100);
        
        if isempty(other_cf)
            near_thresh_idx = [];
        else
            near_thresh_idx = other_cf(all(bsxfun(@(x, y) x < y, other_peaks, 1.5 * tvals), 2));
        end
        near_thresh_peaks = all_peaks(:, near_thresh_idx)';
        dim_filt = find_singular_cols(peaks) & find_singular_cols(near_thresh_peaks);
        if sum(dim_filt) > 1 && length(near_thresh_idx) > 0.5*length(cluster_filter)
            grades(k, 19) = bhat_dist(peaks(:, dim_filt), near_thresh_peaks(:, dim_filt));
        end
        
        dim_filt = find_singular_cols(peaks) & find_singular_cols(all_peaks');
        if any(dim_filt) && ~isempty(other_cf)
            m1 = mahal(peaks(:, dim_filt), peaks(:, dim_filt));
            t1 = median(m1) + 5 * std(m1);
            m = mahal(all_peaks', peaks);
            near_clust_idx = intersect(other_cf, find(m < t1));
            near_clust_peaks = all_peaks(:, near_clust_idx)';
            if length(near_clust_idx) > 0.2 * length(cluster_filter)
                dim_filt = find_singular_cols(peaks) & find_singular_cols(near_clust_peaks);
                grades(k, 20) = bhat_dist(peaks(:, dim_filt), near_clust_peaks(:, dim_filt));
            else
                grades(k, 20) = Inf;
            end
            grades(k, 21) = length(near_clust_idx);
        end
        
        cluster_t = timestamps(cluster_filter);
        duration = 2 * std(cluster_t);
        grades(k, 22) = duration / (timestamps(end) - timestamps(1));
        
        mean_spike = shiftdim(mean(spikes(compare_wire, :, :)), 1);
        if length(cluster_filter) > 1
            [~, ~, mpc] = hfcm(peaks, 2, config);
            grades(k, 23) = mpc;
            dim_filt = find_singular_cols(peaks, 0.5);
            grades(k, 24) = sum(dim_filt);
        
            mean_spike_int = spline(1:length(mean_spike), mean_spike, linspace(1, length(mean_spike), 5000));
            [starthalfpk, endhalfpk] = get_halfpeak_range(mean_spike_int, 0.25);
            if isnan(starthalfpk) || isnan(endhalfpk)
                dur = 0;
            else
                dur = 1.25e3 * (endhalfpk - starthalfpk) / length(mean_spike_int);
            end
            grades(k, 25) = dur;
        else
            grades(k, 23) = 0;
            grades(k, 24) = 0;
            grades(k, 25) = 0;
        end
        
        grades(k, 26) = length(cluster_filter) * 1e6 / (timestamps(end) - timestamps(1));
        
        pks = find_peaks(mean_spike);
        pks = pks{1};
        [~, idx] = max(mean_spike(pks));
        pkidx = pks(idx);
        vals = find_peaks(mean_spike * (-1));
        vals = vals{1};
        has_valley = any(vals > pkidx);
        grades(k, 27) = has_valley;
    end
end