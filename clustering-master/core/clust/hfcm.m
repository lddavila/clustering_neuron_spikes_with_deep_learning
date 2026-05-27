function [the_center, the_U_value, the_mpc_value] = hfcm(the_X, the_k, the_new_config,varargin)

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

    % ---------------------------------------------------------
    % n = 2 through the_k
    % ---------------------------------------------------------
    for c = 2:the_k
        if ~isempty(varargin)
            curV = varargin{1};
            curV = curV(1:c,:);
        else
            curV = V{c-1};
        end
        ksum = zeros(N, 1);

        for q = 1:c-1
            repeated_center = curV(q*ones(N, 1), :);
            ksum = ksum + sum((the_X - repeated_center).^2, 2);
        end

        % Original heuristic: closest point to existing centers
        [~, alpha] = min(ksum);


        Vc = [curV; the_X(alpha, :) + epsilon];

        [cur_center, cur_U] = mod_fcm(the_X, Vc, c, options);

        V{c} = cur_center;
        Us{c} = cur_U;
        mpcs(c) = calculate_mpc(cur_U);
    end

    [the_mpc_value, ind] = max(mpcs);

    the_center = V{ind};
    the_U_value = Us{ind};

end