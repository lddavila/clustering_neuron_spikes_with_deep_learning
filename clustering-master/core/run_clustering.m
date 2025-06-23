function [final_clusters, bad_clusters] = run_clustering(aligned, spike_idx, ir, tvals, refine_spike_idx, config)
%RUN_CLUSTERING Runs the clustering algorithm after preprocessing.
%   clusters = RUN_CLUSTERING(aligned, spike_idx, timestamps, tvals,
%   refine_spike_idx, config) returns the clusters and their grades after
%   clustering and refinement.
%
%   'aligned' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It is the same as 'raw', but with spikes aligned to have the same peak
%   index.
%
%   'spike_idx' are the indices for all spikes remaining after
%   preprocessing.
%
%   'timestamps' are the timestamps for each spike in microseconds
%   (including all spikes, not just the ones remaining after
%   preprocessing).
%
%   'tvals' are the threshold values for each wire in microvolts.
%
%   'refine_spike_idx' are the indices for all spikes to be used in the
%   refinement step (possibly ignoring some spikes from preprocessing).
%
%   'config' is the spikesort configuration struct.
    
    % Make sure that spike_idx and refine_spike_idx perfectly intersect
    [true_spike_idx, refine_cluster_inj] = intersect(refine_spike_idx, spike_idx);
    
    % Spikes to cluster
    spike_aligned = aligned(:, true_spike_idx, :);
    % plot_the_spikes_ver_2(spike_aligned,"In Run_clustering.m",[],[1,2,3,4],[])
    raw_clusters = core_cluster_loop(spike_aligned, @extract_cluster_features, config);

    % plot_the_cf(raw_clusters,aligned,["Called by run\_clustering.m","Before Refinment"]);
    
    % Inject those cluster indices into the set of indices defined by the
    % refine_spike_idx
    inj_clusters = cellmap(@(x) refine_cluster_inj(x), raw_clusters);
    
    if config.DO_REFINEMENT
        % Take the clusters found by `cluster,' and refine them.
        %refined_clusters = refine_clusters(aligned, refine_spike_idx, inj_clusters, ir, tvals, config); %% OG line
        refined_clusters = refine_clusters_ver_2(aligned, refine_spike_idx, inj_clusters, ir, tvals, config);%EDITED BY LUIS DAVID DAVILA
    else
        refined_clusters = cellmap(@(x) refine_spike_idx(x), inj_clusters);
    end
    % plot_the_cf(refined_clusters,aligned,["Called by run\_clustering.m","After Refinment"]);
        
    % Side effect of `cluster' + refinement is that it can output really
    % obviously bad clusters. Remove those.
    good_filt = remove_bad_clusters(aligned, refined_clusters, ir, tvals, config);
    bad_clusters = refined_clusters(~good_filt);
        
    final_clusters = finalize_clusters(aligned, refined_clusters(good_filt), config);
    %plot_the_cf(final_clusters,aligned,["Called by run\_clustering.m","After finalize\_clusters"]);

end