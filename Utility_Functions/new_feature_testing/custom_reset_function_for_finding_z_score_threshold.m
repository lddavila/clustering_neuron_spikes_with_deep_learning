function [initial_observation, info] = custom_reset_function_for_finding_z_score_threshold(config)
    % Domain & starting point
    lower = 3;
    upper = 4;
    z0    = (lower + upper)/2;   % or: lower + (upper-lower)*rand

    % Evaluate ratio at starting z
    cfg = config;
    cfg.DEFAULT_CLUSTERING_Z_SCORES = z0;
    ratio0 = modified_run_entire_clustering_algorithm(cfg);

    % Fill info
    info.z_score              = z0;
    info.last_ratio           = ratio0;
    info.current_lower_bound  = lower;
    info.current_upper_bound  = upper;
    info.tol_z                = 1e-3;   % optional, aligns with step()
    info.max_steps            = 50;     % optional
    info.step_count           = 0;      % optional

    % Observation matches step(): [z, ratio, lower, upper]
    initial_observation = [z0, ratio0, lower, upper];
end
