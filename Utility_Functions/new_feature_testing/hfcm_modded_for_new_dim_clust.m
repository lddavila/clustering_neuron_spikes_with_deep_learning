function [the_center, the_U_value, the_mpc_value] = hfcm_modded_for_new_dim_clust(the_X, the_k, the_new_config,varargin)

N = size(the_X, 1);

V = cell(the_k, 1);
Us = cell(the_k, 1);
mpcs = zeros(the_k, 1);

epsilon = the_new_config.params.CL_HFCM_EPSILON;
options = [2 the_new_config.params.CL_HFCM_NUM_ITER epsilon 0];

% ---------------------------------------------------------
% n = 1 case: do not call mod_fcm
% ---------------------------------------------------------
V{1} = mean(the_X, 1);
Us{1} = ones(1, N);
mpcs(1) = calculate_mpc(Us{1});


curV = varargin{1};

ksum = zeros(N, 1);
q =1;
repeated_center = curV(q*ones(N, 1), :);
ksum = ksum + sum((the_X - repeated_center).^2, 2);


% Original heuristic: closest point to existing centers
[~, alpha] = min(ksum);


Vc = [curV; the_X(alpha, :) + epsilon];

[cur_center, cur_U] = mod_fcm(the_X, curV, size(varargin{1},1), options);

V{1} = cur_center;
Us{1} = cur_U;
mpcs(1) = calculate_mpc(cur_U);

[the_mpc_value, ind] = max(mpcs);

the_center = V{1};
the_U_value = Us{1};

end