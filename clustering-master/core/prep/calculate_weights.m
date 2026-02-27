%this file has been edited by Luis D. Davila and Alexander Friedman 
function [the_calculated_weights, the_dim_aka_channel_clusters] = calculate_weights(the_data, try_ns, config)
%CALCULATE_WEIGHTS Calculates the weights of each dimension, as guided by
%FCM and MPC.
%   [weights, dim_clusters] = CALCULATE_WEIGHTS(data, try_ns,
%   redundant_selection) returns the weights for each dimension, as well as
%   cluster information for each dimension in 'dim_clusters'.
%
%   The rows of 'data' are observations, and the columns of 'data' are
%   dimensions.
%
%   'try_ns' is the maximum number of clusters to try when using FCM.
%
%   'redundant_selection' is a flag determining whether to try to remove
%   redundant dimensions.
%
%   'weights' is a vector with a weight for each dimension in 'data'.
%
%   'dim_clusters' has cluster information from each dimension.
%
%   Uses FCM to cluster each dimension of 'data' separately. Then the
%   configuration with the maximum MPC rating is considered the best
%   configuration. The weight for this dimension is then assigned to be
%   (n-1)^2, where n is the number of clusters in the best configuration.
%
%   See also GET_BEST_CONFIGURATION, CALCULATE_MPC.

    numdims = size(the_data, 2);
    the_calculated_weights = nan(1, numdims);
    the_dim_aka_channel_clusters = cell(1, try_ns);
    for k = 1:numdims
        [n, U] = get_best_configuration(the_data(:, k), try_ns, config);
        if n > 1
            % If there was more than one cluster in the best configuration,
            % get information about the clusters in case we do redundant
            % selection.
            maxU = max(U);
            clusters = cellmap(@find, num2cell(repmat(maxU, [n, 1]) == U, 2));
            s = struct('mpc', calculate_mpc(U), 'clusters', {clusters}, 'dimnum', k);
            if isempty(the_dim_aka_channel_clusters{n})
                the_dim_aka_channel_clusters{n} = s;
            else
                the_dim_aka_channel_clusters{n} = [the_dim_aka_channel_clusters{n} s];
            end
        end
        
        % Assign the weight of the dimension based on the number of
        % clusters found in the best configuration.
        weight = (n-1)^2;
        the_calculated_weights(k) = weight;
    end
%         for d1 = 1:numdims-1
%             if isnan(weights(d1))
%                 for d2 = d1+1:numdims
%                     if isnan(weights(d2))
%                         [~, ~, mpc] = hfcm(data(:, [d1, d2]), try_ns);
%                         if mpc > 0.75
%                             weights([d1, d2]) = 1;
%                             break
%                         end
%                     end
%                 end
%             end
%         end
    
    % Note: This is still a work in progress, so redundant_selection should
    % always be 'false' for now.
    if config.REDUNDANT_DIMENSION_SELECTION
        for k = 2:try_ns
            ss = the_dim_aka_channel_clusters{k};
            for q = 1:length(ss)-1
                cl1 = ss(q);
                if the_calculated_weights(cl1.dimnum) == 0
                    continue
                end
                for r = q+1:length(ss)
                    cl2 = ss(r);
                    overlaps = compute_overlaps(cl1.clusters, cl2.clusters);
                    if min(min(max(overlaps))) > config.params.CL_MIN_REDUNDANT_OVERLAP
                        if cl1.mpc < cl2.mpc
                            the_calculated_weights(cl1.dimnum) = 0;
                            break
                        else
                            the_calculated_weights(cl2.dimnum) = 0;
                        end
                    end
                end
            end
        end
    end
end