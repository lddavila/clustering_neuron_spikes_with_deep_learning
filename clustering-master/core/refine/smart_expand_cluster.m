function new_cluster_idx = smart_expand_cluster(features, cluster_idx, only_peaks, clean, config)
%SMART_EXPAND_CLUSTER Performs a less "safe" method of expanding the
%cluster, but does so in a smart way to avoid errors.
%   expanded_cluster_idx = SMART_EXPAND_CLUSTER(features, cluster_idx,
%   only_peaks, clean) returns the indices of the expanded cluster.
%
%   The rows of 'features' are observations, and each column is a different
%   feature.
%
%   'cluster_idx' are the indices of the cluster.
%
%   'only_peaks' is a flag for whether we're only using the peak features
%
%   'clean' is a flag for whether we want to clean the expanded cluster

    if ~only_peaks
        num_spikes = size(features, 1);
        non_cluster_idx = setdiff(1:num_spikes, cluster_idx);
        data_filt = find_singular_cols(features(non_cluster_idx, :));
        features = features(:, data_filt);
    end
    features = transform_features(features, cluster_idx);
    
    [m, thresh] = get_thresh(features, cluster_idx, clean, config);
    if isnan(thresh)
        new_cluster_idx = [];
        return
    end
    
    in_expan = find(m < thresh);
    
    if clean
        if only_peaks
            num_std = config.params.RF_NUM_STD_PEAKS;
        else
            num_std = config.params.RF_NUM_STD;
        end
        try
            m2 = mahal(features(in_expan, :), features(in_expan, :));
        catch
            new_cluster_idx = cluster_idx;
            return
        end
        fin_expan = in_expan(m2 < median(m2) + num_std * std(m2));
        new_cluster_idx = fin_expan;
    else
        new_cluster_idx = in_expan;
    end
end

function [m, thresh] = get_thresh(features, cluster_idx, clean, config)
    m = mahal(features, features(cluster_idx, :));
    dist = chi2inv(0.99, size(features, 2));
    if clean
        limit = dist * config.params.RF_MAHAL_HIST_BOUND_SCALE;
    else
        limit = dist * config.params.RF_NOCLEAN_MAHAL_HIST_BOUND_SCALE;
    end
    
    [n1, xi1] = hist(m(m < limit), round(limit * config.params.RF_MAHAL_BINSIZE_SCALE));
    f1 = smooth(n1);
    
    [validx, ~] = get_first_valley(f1, true, Inf);
    if validx <= 0
        if clean || isempty(xi1)
            m = [];
            thresh = NaN;
        else
            thresh = xi1(end);
        end
        return
    end
    thresh = xi1(validx);
end