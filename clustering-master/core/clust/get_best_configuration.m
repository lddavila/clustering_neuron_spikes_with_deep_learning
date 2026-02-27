%this file has been edited by Luis D. Davila and Alexander Friedman 
function [n, U] = get_best_configuration(the_data, try_ns_1, config_new)
%GET_BEST_CONFIGURATION Finds the best cluster configuration for given
%data.
%   [n, U] = GET_BEST_CONFIGURATION(data, try_ns) returns the number of
%   clusters 'n' and the output of FCM 'U'.
%
%   The rows of 'data' are observations, and the columns of 'data' are the
%   different dimensions. 'try_ns' is the maximum number of clusters to try
%   (should be at least 2).
%
%   Tries various numbers of clusters as input to a modified FCM, and uses
%   the max MPC rating to determine which is the best configuration.
%
%   If the max MPC is less than 0.75, and we are working on a particular
%   dimension, we set the number of clusters 'n' to be 1, regardless of
%   'U'.
%
%   See also CALCULATE_WEIGHTS, HFCM, CALCULATE_MPC.

    [~, U, mpc] = hfcm(the_data, try_ns_1, config_new);
    num_dims_aka_channels = size(the_data, 2);
    if num_dims_aka_channels == 1 && mpc < config_new.params.CL_MPC_THRESHOLD
        n = 1;
    else
        n = size(U, 1);
    end
end