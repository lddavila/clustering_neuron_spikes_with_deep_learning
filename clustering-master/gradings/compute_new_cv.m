%updated by Luis David Davila and Alexander Friedman
function [the_cv, the_mean_snr] = compute_new_cv(the_rep_wire, the_percent)
    mean_spike = mean(the_rep_wire);
    [starthalfpk, endhalfpk] = get_halfpeak_range(mean_spike, the_percent);
    if isnan(starthalfpk) || isnan(endhalfpk)
        the_cv = NaN;
        the_mean_snr = NaN;
        return
    end
    halfpk = the_rep_wire(:, starthalfpk:endhalfpk);
    V = bsxfun(@minus, halfpk', mean(halfpk'))';
    mean_halfpk = mean_spike(starthalfpk:endhalfpk);
    mean_halfpk_cent = mean_halfpk - mean(mean_halfpk);
    mean_halfpk_norm = mean_halfpk_cent ./ norm(mean_halfpk_cent);
    S = V * mean_halfpk_norm';
    A = sum(S .^ 2, 2);
    Err = sum(V .^ 2, 2) - A;
    snr = A ./ Err;
    the_mean_snr = median(snr);
    each_cv = std(halfpk) ./ mean(halfpk);
    the_cv = max(each_cv);
    the_mean_snr = sum(A ./ sum(V .^2, 2) < 0.7) / length(A);
end