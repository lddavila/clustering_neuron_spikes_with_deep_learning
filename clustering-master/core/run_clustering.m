%this file has been edited by Luis D. Davila and Alexander Friedman 
function [final_clusters, bad_clusters,full_config] = run_clustering(aligned, spike_idx, ir, tvals, refine_spike_idx, config,peak_pcs_file_name,full_config)
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
    
    disp("entered run_clustering.m")
    % Make sure that spike_idx and refine_spike_idx perfectly intersect
    [true_spike_idx, refine_cluster_inj] = intersect(refine_spike_idx, spike_idx);
    
    % Spikes to cluster
    spike_aligned = aligned(:, true_spike_idx, :);

    % disp("finished getting spike aligned")
    %also updated mutated spike windows
    % full_config.mutated_spike_windows = full_config.mutated_spike_windows(true_spike_idx,:);

    % plot_the_spikes_ver_2(spike_aligned,"In Run_clustering.m",[],[1,2,3,4],[])
    full_config.true_spike_idx = true_spike_idx;
    full_config.secondary_spike_windows = full_config.mutated_spike_windows(true_spike_idx,:);
    % disp("about to start core_cluster_loop")
    [raw_clusters,full_config] = core_cluster_loop(spike_aligned, @extract_cluster_features, config,peak_pcs_file_name,full_config);
    % disp("finished core cluster loop")
    % plot_the_cf(raw_clusters,aligned,["Called by run\_clustering.m","Before Refinment"]);
    
    % Inject those cluster indices into the set of indices defined by the
    % refine_spike_idx
    inj_clusters = cellmap(@(x) refine_cluster_inj(x), raw_clusters);
    % plot_at_every_refinement_stage(aligned,"after_inj_mapping",inj_clusters,full_config);
    create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(full_config,aligned,inj_clusters,full_config.which_thresh,"after_inj_mapping")
    full_config.plot_counter = full_config.plot_counter+1;
    if config.DO_REFINEMENT
        % Take the clusters found by `cluster,' and refine them.
        %refined_clusters = refine_clusters(aligned, refine_spike_idx, inj_clusters, ir, tvals, config); %% OG line
        [refined_clusters,full_config ]= refine_clusters_ver_2(aligned, refine_spike_idx, inj_clusters, ir, tvals, config,full_config);%EDITED BY LUIS DAVID DAVILA
    else
        refined_clusters = cellmap(@(x) refine_spike_idx(x), inj_clusters);
    end
    % plot_the_cf(refined_clusters,aligned,["Called by run\_clustering.m","After Refinment"]);
    % plot_at_every_refinement_stage(aligned,"after_cluster_refinement",refined_clusters,full_config);
    create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(full_config,aligned,refined_clusters,full_config.which_thresh,"after_cluster_refinement");
    full_config.plot_counter = full_config.plot_counter + 1;
    % Side effect of `cluster' + refinement is that it can output really
    % obviously bad clusters. Remove those.
    [good_filt,refined_clusters_with_bad_dims_dropped ]= remove_bad_clusters(aligned, refined_clusters, ir, tvals,config,full_config);
    refined_clusters = refined_clusters_with_bad_dims_dropped;
    bad_clusters = refined_clusters(~good_filt);
    % plot_at_every_refinement_stage(aligned,"after_bad_cluster_removal",refined_clusters(good_filt),full_config);
     create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(full_config,aligned,refined_clusters(good_filt),full_config.which_thresh,"after_bad_cluster_removal");
     full_config.plot_counter = full_config.plot_counter+1;
     final_clusters = refined_clusters;
    % final_clusters = finalize_clusters(aligned, refined_clusters(good_filt), config);
    % plot_at_every_refinement_stage(aligned,"after_cluster_finalization",final_clusters,full_config);
    % create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(full_config,aligned,final_clusters,full_config.which_thresh,"after_cluster_finalization")
    % full_config.plot_counter = full_config.plot_counter + 1;
    %plot_the_cf(final_clusters,aligned,["Called by run\_clustering.m","After finalize\_clusters"]);

end