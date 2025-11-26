function [] = get_similarity_score_between_clusters(cluster_1_row,cluster_2_row,config)
cluster_1_ts = cluster_1_row{1,"timestamps"}{1};
cluster_2_ts = cluster_2_row{1,"timestamps"}{1};
config.TIME_DELTA = 0.0002;
get_overlap_percentage_between_2_cluster_ts(cluster_1_ts,cluster_2_ts,config);
cluster_1_channels = cluster_1_row{1,"grades"}{1}{49};
cluster_2_channels = cluster_2_row{1,"grades"}{1}{49};

[overlap,matches_log] = find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config.TIME_DELTA);


end