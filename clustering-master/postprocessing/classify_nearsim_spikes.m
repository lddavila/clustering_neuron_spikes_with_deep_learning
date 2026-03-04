%edited by Luis David Davila and Alexander Friedman
function the_clust_idx = classify_nearsim_spikes(the_raw_wf_data, cluter_filters, the_spikes, the_config)
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

    wire_filter = find_live_wires(the_spikes);
    cluster_peaks = cellmap(@(x) get_peaks(the_raw_wf_data(wire_filter, x, :), true)', cluter_filters);
    spikes_peaks = max(the_spikes, [], 3)';
    spikes_peaks = spikes_peaks(:, wire_filter);
    
    the_clust_idx = zeros(size(spikes_peaks, 1), 1);
    for k = 1:length(cluster_peaks)
        cp = cluster_peaks{k};
        try
            %OG LINE: m = mahal(cp, cp);
            m = mahal_fixed_for_num_unstable(cp,cp);
            st = median(m) + the_config.NS_NUM_STD * std(m);
            %OG LINE: m = mahal(spikes_peaks, cp);
            m = mahal_fixed_for_num_unstable(spikes_peaks,cp);
        catch
            continue
        end
        the_clust_idx(m < st) = k;
    end
end