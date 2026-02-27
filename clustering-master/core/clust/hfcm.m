%this file has been edited by Luis D. Davila and Alexander Friedman 
function [the_center, the_U_value, the_mpc_value] = hfcm(the_X, the_k, the_new_config)
%HFCM Heuristic FCM algorithm which is at least consistent, if not optimal.
%   [center, U, mpc] = HFCM(X, k) returns the information for the best
%   cluster configuration given parameter 'n' as the number of clusters for
%   2 <= n <= k.
%
%   The rows of 'X' are observations, and the columns of 'X' are
%   dimensions.
%
%   'center' is a matrix in which the rows correspond to coordinates for
%   the center of a cluster.
%
%   'U' is the output of FCM.
%
%   'mpc' is the Modified Partition Coefficient value for the cluster
%   configuration returned.
%
%   The algorithm works by specifying the initial configuration for FCM
%   instead of randomly sampling. The initial location of the centers is
%   chosen by:
%   1) Taking the centers from the previous configuration of FCM
%   2) Making the new center the observation closest to the previous
%   centers.
%
%   See also MOD_FCM.

    N = size(the_X, 1); % Number of observations
    V = cell(the_k, 1); % Number of configurations
    
    % Initialize the first center to be the mean of the observations.
    V{1} = mean(the_X);
    
    mpcs = zeros(the_k, 1);
    Us = cell(the_k, 1);
    
    epsilon = the_new_config.params.CL_HFCM_EPSILON; % Small value for FCM's objective function
    
    for c = 2:the_k
        curV = V{c-1};
        
        % For each existing center, compute the distance of each
        % observation to the center, and add them all up.
        ksum = zeros(N, 1);
        for q = 1:c-1
            the_center = curV(q*ones(N, 1), :);
            ksum = ksum +  sum((the_X - the_center) .^ 2, 2);
        end
        
        % Take the argmin of ksum to get the observation closest to the
        % existing centers.
        [~, alpha] = min(ksum);
        
        % Make the new center that observation + epsilon to avoid
        % singularities when running FCM.
        Vc = [curV ; the_X(alpha, :) + epsilon];
        
        % Use the new centers as parameters to FCM.
        options = [2 the_new_config.params.CL_HFCM_NUM_ITER epsilon 0];
        [the_center, the_U_value] = mod_fcm(the_X, Vc, c, options);
        
        V{c} = the_center;
        Us{c} = the_U_value;
        the_mpc_value = calculate_mpc(the_U_value);
        mpcs(c) = the_mpc_value;
    end
    
    % Only return the information concerning the cluster configuration with
    % maximum MPC.
    [the_mpc_value, ind] = max(mpcs);
    the_center = V{ind};
    the_U_value = Us{ind};
end