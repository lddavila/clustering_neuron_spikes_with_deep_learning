function [initial_observation,info] = custom_reset_function_for_finding_z_score_threshold(config)
copy_of_config = config;
copy_of_config.DEFAULT_CLUSTERING_Z_SCORES = 3.5;
meets_acc_ratio = modified_run_entire_clustering_algorithm(copy_of_config);
initial_state = [random_z_score_to_use,0];
initial_observation = initial_state;
info.last_ratio = meets_acc_ratio;
info.z_score = random_z_score_to_use;
end