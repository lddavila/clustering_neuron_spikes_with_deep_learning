function refined_clusters = refine_clusters(spikes, refine_idx_inj, clusters, ir, tvals, config)
%REFINE_CLUSTERS Manages refinement of all of the clusters after
%clustering.
%   refined_clusters = REFINE_CLUSTERS(spikes, refine_idx_inj, clusters)
%   returns a cell of indices for the refined clusters.
%
%   'spikes' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%
%   'refine_idx_inj' is the vector of indices used to inject indices from
%   the refinement space to the space of spikes before preprocessing.
%
%   'clusters' is a cell array of indices for the clusters in the
%   refinement space.
%
%   'ir' are the input range values for each wire in microvolts.
%
%   'tvals' are the threshold values for each wire in microvolts.
%
%   'config' is the spikesort configuration struct.

    refined_clusters = cell(size(clusters));
    refine_spikes = spikes(:, refine_idx_inj, :);
    features = extract_refine_features(refine_spikes);
    peaks = get_peaks(refine_spikes, true)';
    warning_was_thrown = false;%added by Luis David Davila
    for k = 1:length(clusters)
        cluster_idx = clusters{k};
        % plot_clusters_spike_refinement("Before Refinment In refine\_clusters.m",k,peaks,cluster_idx,4)
        % plot_aligned_for_refinment("Before Refinment in refine_clusters.m",k,spikes,cluster_idx,4);
        [raw_refined_cluster_idx, backup] = refine_cluster(features, peaks, cluster_idx, ir, tvals, config);
        % plot_clusters_spike_refinement("After Refinment In refine\_clusters.m",k,peaks,raw_refined_cluster_idx,4)
        % plot_aligned_for_refinment("After Refinment in refine_clusters.m",k,spikes,raw_refined_cluster_idx,4);
        refined_cluster_idx = refine_idx_inj(raw_refined_cluster_idx);
        if ~isempty(refined_cluster_idx) && ...
                ~isempty(backup) && ...
                ~remove_bad_clusters(spikes, {refined_cluster_idx}, ir, tvals, config)
            refined_cluster_idx = refine_idx_inj(backup);
        end
        [warnMsg_1, ~] = lastwarn(''); %added by Luis David Davila
        if ~isempty(warnMsg_1)%added by Luis David Davila
            warning_was_thrown = true;%added by Luis David Davila
            warnMsg = warnMsg_1;
        end%added by Luis David Davila
        refined_clusters{k} = refined_cluster_idx;
    end
    if warning_was_thrown%added by Luis David Davila
        warning(warnMsg)%added by Luis David Davila
    end%added by Luis David Davila
    refined_clusters = refined_clusters(~cellfun('isempty', refined_clusters));
end