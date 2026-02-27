%this file has been edited by Luis D. Davila and Alexander Friedman 
function the_new_cluster_idx = smart_expand_cluster(the_features, the_cluster_idx, only_the_peaks, the_clean, the_new_config)
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

    if ~only_the_peaks
        num_spikes = size(the_features, 1);
        non_cluster_idx = setdiff(1:num_spikes, the_cluster_idx);
        data_filt = find_singular_cols(the_features(non_cluster_idx, :));
        the_features = the_features(:, data_filt);
    end
    the_features = transform_features(the_features, the_cluster_idx);
    
    [m, thresh] = get_thresh(the_features, the_cluster_idx, the_clean, the_new_config);
    if isnan(thresh)
        the_new_cluster_idx = [];
        return
    end
    
    in_expan = find(m < thresh);
    
    if the_clean
        if only_the_peaks
            num_std = the_new_config.params.RF_NUM_STD_PEAKS;
        else
            num_std = the_new_config.params.RF_NUM_STD;
        end
        try
            %OG LINE: m2 = mahal(features(in_expan, :), features(in_expan, :));
            %replaced the og line to use the guarded version of mhal
            %distance which subs in generalized Mahalanobis when the matrix
            %is unstable
            m2 = mahal_fixed_for_num_unstable(the_features(in_expan,:),the_features(in_expan,:));
        catch
            the_new_cluster_idx = the_cluster_idx;
            return
        end
        fin_expan = in_expan(m2 < median(m2) + num_std * std(m2));
        the_new_cluster_idx = fin_expan;
    else
        the_new_cluster_idx = in_expan;
    end
end

function [m, thresh] = get_thresh(features, cluster_idx, clean, config)
    %OG LINE: m =  m = mahal(features, features(cluster_idx, :));
    %changed the og line cause instability was popping up too much so
    %rewrote the mahal function with a catch to stabilize the result
    %it can be changed bakc, and I might choose to just normalize the
    %features instead if this proves insufficent
    m = mahal_fixed_for_num_unstable(features, features(cluster_idx, :));
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