function good_filt = remove_bad_clusters(aligned, cfs, ir, tvals, config)
%REMOVE_BAD_CLUSTERS Removes obviously bad clusters before they can do any
%harm!
%   good_filt = REMOVE_BAD_CLUSTERS(aligned, cfs)
%
%   'aligned' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It is the same as 'raw', but with spikes aligned to have the same peak
%   index.
%
%   'cfs' is a cell array of indices for each cluster.
%
%   'good_filt' is a logical index array for which clusters are good
%   (not terrible).

% TODO: special behavior for clusters far from tvals.

    good_filt = true(1, length(cfs));
    all_peaks = get_peaks(aligned, true)';
    for k = 1:length(cfs)
        cf = cfs{k};
        peaks = all_peaks(cf, :);
        if config.params.RB_TRUST_SMALL_ISOLATED && length(cf) < 1000
            non_cluster_idx = setdiff(1:size(all_peaks, 1), cf);
            bdist = bhat_dist(peaks, all_peaks(non_cluster_idx, :));
            if bdist > 2
                % Small cluster far from everything else, so better to not
                % remove it and instead assume it's ok.
                continue
            end
        end
        
        mean_peaks = mean(peaks);
        far_thresh = config.TRUST_FAR_NEURONS && any(mean_peaks > 3 * tvals' & mean_peaks ./ ir' > 0.6);
        if far_thresh
            % Very distant cluster from thresh - do not attempt bad cluster removal
            continue
        end
        num_peaks = size(peaks, 2);
        [~, peakpcs] = pca(peaks);
        data = zscore([peaks, peakpcs(:, 1:num_peaks-1)]);
        dim_filter = select_dimensions_dip(data, config);
        good_filt(k) = ~any(dim_filter); %if any of the dimensions are bad then the entire cluster is scrapped
        if ~good_filt(k) 
            % disp("Cluster " + string(k) + " had " + string(sum(dim_filter))+" bad dimensions and will be removed");
        end
    end
end