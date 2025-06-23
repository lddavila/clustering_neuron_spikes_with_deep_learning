function scaled_features = transform_features(features, cluster_idx)
%TRANSFORM_FEATURES Scales each feature in the feature space, thus
%performing a basic linear transformation on the space.
%   scaled_features = TRANSFORM_FEATURES(features, cluster_idx) returns the
%   same features after scaling.
%
%   The rows of 'features' are observations, and each column is a different
%   feature.
%
%   'cluster_idx' are the indices of the cluster.
%
%   Scales each feature by (1 - LRatio) with respect to the cluster. Since
%   lower LRatios imply that the cluster is more isolated, each feature
%   scales proportionally to how isolated the cluster is from the rest of
%   the data in that feature alone.

    num_spikes = size(features, 1);
    
    feature_filter = find_singular_cols(features(cluster_idx, :));
    filtered_features = features(:, feature_filter);
    ratings = 1 - rate_clusters({cluster_idx}, filtered_features)';
    good_ratings = ratings > 0;
    scaled_features = filtered_features(:, good_ratings) .* repmat(ratings(good_ratings), [num_spikes, 1]);
end