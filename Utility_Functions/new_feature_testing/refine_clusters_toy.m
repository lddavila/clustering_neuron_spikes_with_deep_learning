function [refined_clusters,full_config]= refine_clusters_toy(spikes, refine_idx_inj, clusters, ir, tvals, config,full_config,peaks)

refined_clusters = cell(size(clusters));
refine_spikes = spikes(:, refine_idx_inj, :);
features = extract_refine_features(refine_spikes);

k=1;
while k<=length(clusters)
    cluster_idx = clusters{k};
    % plot_clusters_spike_refinement("Before Refinment In refine\_clusters.m",k,peaks,cluster_idx,4)
    % plot_aligned_for_refinment("Before Refinment in refine_clusters.m",k,spikes,cluster_idx,4);

    [raw_refined_cluster_idx, backup] = refine_cluster(features, peaks, cluster_idx, ir, tvals, config);



    % plot_clusters_spike_refinement("After Refinment In refine\_clusters.m",k,peaks,raw_refined_cluster_idx,4)
    % plot_aligned_for_refinment("After Refinment in refine_clusters.m",k,spikes,raw_refined_cluster_idx,4);

    refined_cluster_idx = refine_idx_inj(raw_refined_cluster_idx);
    condition_for_remove_bad_clusters = remove_bad_clusters(spikes, {refined_cluster_idx}, ir, tvals, config,full_config);
    if ~isempty(refined_cluster_idx) && ...
            ~isempty(backup) && ...
            ~condition_for_remove_bad_clusters
        refined_cluster_idx = refine_idx_inj(backup);
    end
    refined_clusters{k} = refined_cluster_idx;
    k=k+1;
end
refined_clusters = refined_clusters(~cellfun('isempty', refined_clusters));
end