function [refined_cluster_idx, backup] = refine_cluster(features, peaks, cluster_idx, ir, tvals, config)
%REFINE_CLUSTER Refines a particular cluster in a given feature space.
%   refined_cluster_idx = REFINE_CLUSTER(features, cluster_idx,
%   is_bad_isolation) returns in the indices of the refined cluster,
%   assuming refinement was successful.
%
%   The rows of 'features' are observations, and each column is a different
%   feature.
%
%   'cluster_idx' are the indices of the cluster.
%
%   'is_bad_isolation' is a flag for whether the cluster is considered
%   badly isolated by the isolation heuristic.
%
%   See also EXTRACT_CORE, TRANSFORM_FEATURES, SMART_EXPAND_CLUSTER,
%   REFINE_CLUSTERS.

% TODO: Add special behavior for clusters near tvals

    backup = [];
    refined_cluster_idx = [];
    peak_filt = find_singular_cols(peaks(cluster_idx, :)); %checks if any columns have less than 5% unique values 
    if ~any(peak_filt)
        return
    end
    
    cluster_core_idx = extract_core(features, cluster_idx, config);

    r_cluster_idx = smart_expand_cluster(features, cluster_core_idx, false, true, config);
    if isempty(r_cluster_idx)
        refined_cluster_idx = [];
        return
    end
    
    non_cluster_idx = setdiff(1:size(features,1), r_cluster_idx);
    rating = compute_lratio(peaks(r_cluster_idx, :), peaks(non_cluster_idx, :));
    mean_peaks = mean(peaks(r_cluster_idx, :));
    
    far_thresh = config.TRUST_FAR_NEURONS && ...
        any(mean_peaks > config.params.TF_NUM_THRESH * tvals' & mean_peaks ./ ir' > config.params.TF_IR_PERCENT);
    if rating < config.params.RF_GOOD_RATING || far_thresh
        new_core = extract_core(features, extract_core(features, r_cluster_idx, config), config);
        if isempty(new_core)
            refined_cluster_idx = [];
            return;
        end
        clean = ~far_thresh;
        peak_filt = find_singular_cols(peaks(new_core, :));
        
        refined_cluster_idx = smart_expand_cluster(peaks(:, peak_filt), new_core, true, clean, config);
        backup = r_cluster_idx;
    else
        refined_cluster_idx = r_cluster_idx;
    end
end