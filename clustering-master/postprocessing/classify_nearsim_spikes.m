function clust_idx = classify_nearsim_spikes(raw, cf, spikes, config)
%CLASSIFY_NEARSIM_SPIKES Classifies nearly simultaneous spikes to existing
%clusters.
%   clust_idx = CLASSIFY_NEARSIM_SPIKES(raw, cf, spikes)
%
%   'raw' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It represents the raw spike samples recorded.
%
%   'cf' is a cell array, where each element is a set of indices specifying
%   which spikes belong to the cluster.
%
%   'spikes' are the nearly simultaneous spikes to classify (similar to
%   'raw' in structure)
%
%   'clust_idx' is a vector with values corresponding to the cluster
%   classification for each spike.

    wire_filter = find_live_wires(spikes);
    cluster_peaks = cellmap(@(x) get_peaks(raw(wire_filter, x, :), true)', cf);
    spikes_peaks = max(spikes, [], 3)';
    spikes_peaks = spikes_peaks(:, wire_filter);
    
    clust_idx = zeros(size(spikes_peaks, 1), 1);
    for k = 1:length(cluster_peaks)
        cp = cluster_peaks{k};
        try
            m = mahal(cp, cp);
            st = median(m) + config.NS_NUM_STD * std(m);
            m = mahal(spikes_peaks, cp);
        catch
            continue
        end
        clust_idx(m < st) = k;
    end
end