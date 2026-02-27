%this file has been edited by Luis D. Davila and Alexander Friedman 
function [the_n, the_U] = cluster_prepare_data(the_filtered_raw, the_cluster_ns, the_extract_features_fn, the_new_config,peak_pcs_file_name)

%CLUSTER_PREPARE_DATA Prepares the data for clustering.
%   [n, U] = CLUSTER_PREPARE_DATA(filtered_raw, cluster_ns, config) returns
%   the number of clusters (n) and the fuzzy partition matrix (U).
    the_n = 0;
    the_U = [];
    
    num_spikes = size(the_filtered_raw, 2);
    if num_spikes < the_new_config.params.CL_MIN_CLUSTER_SPIKES 
        return
    end

    [cluster_data, supp_data] = the_extract_features_fn(the_filtered_raw,the_new_config,peak_pcs_file_name);
    
    % Determine which clustering is best using the MPC validity index
    data = [cluster_data, supp_data];
    % dimension_names = ["1st Wire peak(voltage)","2nd Wire Peak (Voltage)","3rd Wire Peak (Voltage)","4th Wire Peak (Voltage)",...
    %     "Wire 1 PC1","Wire 2 PC2","Wire 3 PC3","Wire 4 PC4",...
    %     "Wire 1 Peak PC1","Wire 2 Peak PC2","Wire 3 Peak PC3"];
    weights = calculate_weights(data, the_new_config.WEIGHT_NS, the_new_config);
    % fprintf('%d ', weights)
    % fprintf('\n')
    good_weights_idx = find(weights);
    weights = weights(good_weights_idx);
    % dimension_names = dimension_names(good_weights_idx);
    if isempty(weights)
        the_n = 1;
        return
    end
    
    if the_new_config.USE_DIMENSION_SELECTION
        resized_data = data(:, good_weights_idx);
        % Perform space transformation on normalized data
        weighted_data = resized_data .* repmat(weights, size(resized_data, 1), 1);
    else
        weighted_data = data;
    end
    [the_n, the_U] = get_best_configuration(weighted_data, the_cluster_ns, the_new_config);
    

    % cluster_indexes_from_first_pass =plot_cluster_after_data_has_been_prepared(U,weighted_data,n,"Called by cluster\_prepare\_data.m",dimension_names);


end