function cluster_core_idx = extract_core(features, cluster_idx, config)
%EXTRACT_CORE Extracts the core of a cluster in a given feature space.
%   cluster_core_idx = EXTRACT_CORE(features, cluster_idx) returns the
%   indices of the cluster core in the feature space.
%
%   The rows of 'features' are observations, and each column is a different
%   feature.
%
%   'cluster_idx' are the indices of the cluster.
%
%   See also REFINE_CLUSTER, NAIVE_EXPAND_CLUSTER, SMART_EXPAND_CLUSTER.

    cluster_features = features(cluster_idx, :);
    data_filt = find_singular_cols(cluster_features);
    cluster_features = cluster_features(:, data_filt);
    % cluster_features = cluster_features * 100;
    num_spikes = length(cluster_idx);
    
    % Calculates Euclidean distance from each point to the center of the
    % cluster.
    if size(cluster_features,1) < size(cluster_features,2)
        disp("warning")
        disp("cluster features has fewer row than columns")
        disp("will error")
        disp("occurs in extract_core.m")
    end
    dists = mahal(cluster_features, cluster_features);
    [warnMsg, warnId] = lastwarn;
    if contains(warnMsg,'Matrix is close to singular or badly scaled. Results may be inaccurate')
        warning("");
        % error("mahal.m threw the warning matrix is close to singular or badly scaled, so we won't use the current tetrode")
        % print("mahal.m thre the warning matrix is close to singular or badly scaled, so we won't use the current tetrode")
        % cluster_core_idx =[];
        % return;
    end
    if contains(warnMsg,'Matrix is singular to working')
        warning("");
        % error("mahal.m threw the warning Warning: Matrix is singular to working precision. ")
    end
    [~, ind] = sort(dists);

    % Ideally the cluster core consists of 30% of the spikes in the
    % cluster.
    num_core_spikes = round(config.params.RF_CORE_CLUSTER_PERCENT * num_spikes);
    
    % However, when a cluster is quite small, the cluster core can consist
    % of as many as 60% of the spikes in the cluster.
    upper_bound = min(round(config.params.RF_CORE_UPPER_BOUND_PERCENT * num_spikes), ...
                      max(config.params.RF_CORE_UNTIL_BOUND, num_core_spikes));
    
    core_idx = ind(1:upper_bound);
    cluster_core_idx = cluster_idx(core_idx);
end