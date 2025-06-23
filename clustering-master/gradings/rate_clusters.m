function ratings = rate_clusters(clusters, data)
%RATE_CLUSTERS Wrapper function around compute_lratio which computes cluster
%data and other data before running compute_lratio.
%   ratings = RATE_CLUSTERS(clusters, data)
%
%   See also COMPUTE_LRATIO, TRANSFORM_FEATURES.

    num_clusters = length(clusters);
    total_spikes = 1:size(data, 1);
    num_dims = size(data, 2);
    ratings = nan(num_dims, num_clusters);
    for f = 1:num_clusters
        cluster_spikes = clusters{f};
        cluster_data = data(cluster_spikes, :);
        other_spikes = setdiff(total_spikes, cluster_spikes);
        other_data = data(other_spikes, :);
        for d = 1:num_dims
            ratings(d, f) = compute_lratio(cluster_data, other_data, d);
        end
    end
end