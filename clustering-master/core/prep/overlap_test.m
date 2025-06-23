function [passed, good] = overlap_test(dim, config,dimension_number)
%OVERLAP_TEST Performs the overlap test as part of dimension selection.
%   [passed, good] = OVERLAP_TEST(dim) returns whether the dimension passed
%   the overlap test, as well as whether it can be considered a "good"
%   dimension.
%
%   The idea is to examine valleys and estimate distribution overlap by
%   evaluating the relationship between the valley and the two surrounding
%   peaks.
    
    passed = false;
    good = false;
    
    % k * width estimation derived from ksdensity, assuming sig = 1 because
    % of zscore normalization.
    k = config.params.OT_WIDTH_SCALING_FACTOR;
    width = k * (4/(3 * length(dim)))^(1/5);
    [f, xi] = ksdensity(dim, 'width', width);
    % 
    % figure();
    % plot(xi,f);
    % hold on;
    % xlabel("Estimated Function Values");
    % ylabel("Evalutation Points");
    % hold off;
    % close all;
    
    pks = find_peaks(f);
    if isempty(pks)
        disp("No Peaks Found for dim" + string(dimension_number))
    end
    valleys = find_peaks(-1 * f);
    if isempty(valleys)
        disp("No valleys found for dim" + string(dimension_number))
    end
    pks = pks{1};
    valleys = valleys{1};
    
    if ~isempty(pks) && length(dim) > config.params.OT_MIN_SPIKES_LARGE_CLUSTER
        [p, ind] = max(f(pks));
        pkind = pks(ind);
        vals = abs(diff(f)) < config.params.OT_EPSILON;
        start = max(pkind - config.params.OT_PEAK_RADIUS, 1);
        fin   = min(pkind + config.params.OT_PEAK_RADIUS, length(vals));
        vals(start:fin) = false;
        if any(f(vals) ./ p > config.params.OT_HIGH_VALLEY_THRESH)
            passed = true;
            return
        end
    end
    
    for valley = valleys'
        pk_before = find(pks < valley);
        pk_after = find(pks > valley);
        
        if ~isempty(pk_before) && ~isempty(pk_after)
            val = f(valley);
            pkval_before = max(f(pks(pk_before)));
            pkval_after = max(f(pks(pk_after)));
            minpk = min(pkval_before, pkval_after);
            
            if minpk == pkval_before
                maxpk = pkval_after;
                csum = sum(dim < xi(valley));
            else
                maxpk = pkval_before;
                csum = sum(dim > xi(valley));
            end
            min_size = min(config.params.OT_MIN_CLUSTER_PERCENT * length(dim), ...
                           config.params.OT_MIN_CLUSTER_SIZE_UPPER_BOUND);
            if val < config.params.OT_MAX_VALLEY_PERCENT * maxpk && csum > min_size
                % Significant dip
                passed = true;
                if val < config.params.OT_MAX_SIG_VALLEY_PERCENT * maxpk || ...
                        (minpk > config.params.OT_HEIGHT_THRESH * maxpk && ...
                            val < config.params.OT_HEIGHT_THRESH * maxpk)
                    good = true;
                end
                return
            end
        end
    end
end