%this file has been edited by Luis D. Davila and Alexander Friedman 
function the_new_clusters = finalize_clusters(the_aligned, the_clusters, the_new_config)
%NOTE TO ME: I REMOVED THIS FROM THE PIPELINE BECAUSE IT WAS UNNECESSARILY
%RETURNING CLUSTERS TO THEIR pre dimension dropped state 
%FINALIZE_CLUSTERS Performs a final expansion in the peak space to "fill"
%the space of the cluster.
%   new_clusters = FINALIZE_CLUSTERS(aligned, clusters) returns the new,
%   "filled" clusters.
    the_new_clusters = cell(size(the_clusters));
    peaks = get_peaks(the_aligned, true)';
    for c = 1:length(the_clusters)
        cl = the_clusters{c};
        if length(cl) < the_new_config.params.FC_MIN_NUM_SPIKES
            the_new_clusters{c} = [];
            continue
        end
        cl_peaks = peaks(cl, :);
        wire_filter = find_singular_cols(cl_peaks);
        g = gmdistribution.fit(cl_peaks(:, wire_filter), 1);
        m = g.mahal(peaks(:, wire_filter));
        m2 = g.mahal(cl_peaks(:, wire_filter));
        the_new_clusters{c} = union(cl, find(m < median(m2) + std(m2)));
    end
    the_new_clusters = the_new_clusters(~cellfun('isempty', the_new_clusters));
end