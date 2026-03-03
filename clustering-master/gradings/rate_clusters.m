%updated by Luis David Davila and Alexander Friedman
function the_cluster_ratings = rate_clusters(the_clusters, the_data)
%RATE_CLUSTERS Wrapper function around compute_lratio which computes cluster
%data and other data before running compute_lratio.
%   ratings = RATE_CLUSTERS(clusters, data)
%
%   See also COMPUTE_LRATIO, TRANSFORM_FEATURES.

    num_clusters = length(the_clusters);
    total_spikes = 1:size(the_data, 1);
    num_dims = size(the_data, 2);
    the_cluster_ratings = nan(num_dims, num_clusters);
    for f = 1:num_clusters
        cluster_spikes = the_clusters{f};
        cluster_data = the_data(cluster_spikes, :);
        other_spikes = setdiff(total_spikes, cluster_spikes);
        other_data = the_data(other_spikes, :);
        for d = 1:num_dims
            the_cluster_ratings(d, f) = compute_lratio(cluster_data, other_data, d);
        end
    end
end