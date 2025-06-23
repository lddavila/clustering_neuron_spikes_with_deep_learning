function new_clusters = finalize_clusters(aligned, clusters, config)
%FINALIZE_CLUSTERS Performs a final expansion in the peak space to "fill"
%the space of the cluster.
%   new_clusters = FINALIZE_CLUSTERS(aligned, clusters) returns the new,
%   "filled" clusters.
    new_clusters = cell(size(clusters));
    peaks = get_peaks(aligned, true)';
    for c = 1:length(clusters)
        cl = clusters{c};
        if length(cl) < config.params.FC_MIN_NUM_SPIKES
            new_clusters{c} = [];
            continue
        end
        cl_peaks = peaks(cl, :);
        wire_filter = find_singular_cols(cl_peaks);
        g = gmdistribution.fit(cl_peaks(:, wire_filter), 1);
        m = g.mahal(peaks(:, wire_filter));
        m2 = g.mahal(cl_peaks(:, wire_filter));
        new_clusters{c} = union(cl, find(m < median(m2) + std(m2)));
    end
    new_clusters = new_clusters(~cellfun('isempty', new_clusters));
end