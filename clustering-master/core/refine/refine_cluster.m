%this file has been edited by Luis D. Davila and Alexander Friedman 
function [the_refined_cluster_idx, the_backup] = refine_cluster(the_features, the_peaks, the_cluster_idx, the_ir, the_tvals, the_new_config)
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

    the_backup = [];
    the_refined_cluster_idx = [];
    peak_filt = find_singular_cols(the_peaks(the_cluster_idx, :)); %checks if any columns have less than 5% unique values 
    if ~any(peak_filt)
        return
    end
    
    cluster_core_idx = extract_core(the_features, the_cluster_idx, the_new_config);


    r_cluster_idx = smart_expand_cluster_ver_2(the_features,cluster_core_idx,false,true,the_new_config);
    
    if isempty(r_cluster_idx)
        the_refined_cluster_idx = [];
        return
    end
    
    non_cluster_idx = setdiff(1:size(the_features,1), r_cluster_idx);
    rating = compute_lratio(the_peaks(r_cluster_idx, :), the_peaks(non_cluster_idx, :));
    mean_peaks = mean(the_peaks(r_cluster_idx, :));
    
    far_thresh = the_new_config.TRUST_FAR_NEURONS && ...
        any(mean_peaks > the_new_config.params.TF_NUM_THRESH * the_tvals' & mean_peaks ./ the_ir' > the_new_config.params.TF_IR_PERCENT);
    if rating < the_new_config.params.RF_GOOD_RATING || far_thresh
        try
            new_core = extract_core(the_features, extract_core(the_features, r_cluster_idx, the_new_config), the_new_config);
        catch ME
            new_core = [];
        end
        if isempty(new_core)
            the_refined_cluster_idx = [];
            return;
        end
        clean = ~far_thresh;
        peak_filt = find_singular_cols(the_peaks(new_core, :));
        
        the_refined_cluster_idx = smart_expand_cluster(the_peaks(:, peak_filt), new_core, true, clean, the_new_config);
        the_backup = r_cluster_idx;
    else
        the_refined_cluster_idx = r_cluster_idx;
    end
end