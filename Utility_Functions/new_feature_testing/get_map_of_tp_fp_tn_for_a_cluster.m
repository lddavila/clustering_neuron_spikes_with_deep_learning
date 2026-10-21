function [mask] = get_map_of_tp_fp_tn_for_a_cluster(ground_truth_cell_array,max_overlap_unit,cluster_ts,timestamps,tol)

ground_truth_unit_idxs = ground_truth_cell_array{max_overlap_unit};
gt_ts = timestamps(ground_truth_unit_idxs);
[~,loc_of_tp_in_cluster] = ismembertol(gt_ts,cluster_ts,tol,DataScale=1);
mask = zeros(length(cluster_ts),1);
mask(loc_of_tp_in_cluster(loc_of_tp_in_cluster~=0)) = 1;
end