%this file has been edited by Luis D. Davila and Alexander Friedman
function [final_clusters, bad_clusters,full_config,is_bad_cluster] = run_clustering(aligned, spike_idx, ir, tvals, refine_spike_idx, config,peak_pcs_file_name,full_config)
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

%true_spike_idx is the idx of spikes that are both in refine_spike_idx (OG
%Data) and spike_idx (spikes that were filtered by their pmv)
%refine_cluster_inj is the index of where the intersecting spikes of both
%refine_spike_idx and spike_idx appear in refine_spike_idx
%for example if
%refine_spike_idx = [4 3 2 1]
%spike_idx = [2 4]
%then
%true_spike_idx = [2,4]
%refine_cluster_inj = [1,3]
%refine_cluster_inj maps backs to refine_spike_idx
%refine_spike_idx & spike_idx both map back to the aligned
[true_spike_idx, refine_cluster_inj] = intersect(refine_spike_idx, spike_idx);



% take the spikes that belong to both refine_spike_idx and spike_idx, these waveforms are
% what raw_clusters returned by core_cluster_loop actually refer to 
spike_aligned = aligned(:, true_spike_idx, :);

%it is  important to keep in mind that the clusters that come back
%currently do not align with refine_spike_idx NOR spike_idx they align with
%the indexes shared between them 

if full_config.debug_with_ground_truth
    full_config.true_spike_idx = true_spike_idx;
    full_config.secondary_spike_windows = full_config.mutated_spike_windows(true_spike_idx,:);
end


[raw_clusters,full_config] = core_cluster_loop(spike_aligned, @extract_cluster_features, config,peak_pcs_file_name,full_config);


%raw_clusters contains idxs which relate to spike_aligned
% `refine_cluster_inj` maps each position in `spike_aligned` to the
% corresponding position in `refine_spike_idx`.
%
% Therefore, `inj_clusters` contains positions within `refine_spike_idx`;
inj_clusters = cellmap(@(x) refine_cluster_inj(x), raw_clusters);


if full_config.has_ground_truth && full_config.debug_with_ground_truth
    create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(full_config,aligned,inj_clusters,full_config.which_thresh,"afterinjmapping")
    full_config.plot_counter = full_config.plot_counter+1;
end
if config.DO_REFINEMENT
    % Take the clusters found by `cluster,' and refine them.
    %refined_clusters = refine_clusters(aligned, refine_spike_idx, inj_clusters, ir, tvals, config); %% OG line
    [refined_clusters,full_config ]= refine_clusters_ver_2(aligned, refine_spike_idx, inj_clusters, ir, tvals, config,full_config);%EDITED BY LUIS DAVID DAVILA
else
    %refied clusters maps the indexes back to the original aligned
    refined_clusters = cellmap(@(x) refine_spike_idx(x), inj_clusters);
end
% plot_the_cf(refined_clusters,aligned,["Called by run\_clustering.m","After Refinment"]);
% plot_at_every_refinement_stage(aligned,"after_cluster_refinement",refined_clusters,full_config);
if full_config.has_ground_truth && full_config.debug_with_ground_truth
    create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(full_config,aligned,refined_clusters,full_config.which_thresh,"afterclusterrefinement");
    full_config.plot_counter = full_config.plot_counter + 1;

end

% Side effect of `cluster' + refinement is that it can output really
% obviously bad clusters. Remove those.
[good_filt,refined_clusters_with_bad_dims_dropped ]= remove_bad_clusters(aligned, refined_clusters, ir, tvals,config,full_config);
refined_clusters = refined_clusters_with_bad_dims_dropped;
bad_clusters = refined_clusters(~good_filt);


if full_config.has_ground_truth && full_config.debug_with_ground_truth
    create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(full_config,aligned,refined_clusters(good_filt),full_config.which_thresh,"afterbadclusterremoval");
    full_config.plot_counter = full_config.plot_counter+1;
end
final_clusters = refined_clusters;

% final_clusters = finalize_clusters(aligned, refined_clusters(good_filt), config);
% plot_at_every_refinement_stage(aligned,"after_cluster_finalization",final_clusters,full_config);
% create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(full_config,aligned,final_clusters,full_config.which_thresh,"after_cluster_finalization")
% full_config.plot_counter = full_config.plot_counter + 1;
%plot_the_cf(final_clusters,aligned,["Called by run\_clustering.m","After finalize\_clusters"]);
is_bad_cluster = ~good_filt;
end