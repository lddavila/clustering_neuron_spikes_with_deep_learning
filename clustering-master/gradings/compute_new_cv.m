function [cv, mean_snr] = compute_new_cv(rep_wire, percent)
    mean_spike = mean(rep_wire);
    [starthalfpk, endhalfpk] = get_halfpeak_range(mean_spike, percent);
    if isnan(starthalfpk) || isnan(endhalfpk)
        cv = NaN;
        mean_snr = NaN;
        return
    end
    halfpk = rep_wire(:, starthalfpk:endhalfpk);
    V = bsxfun(@minus, halfpk', mean(halfpk'))';
    mean_halfpk = mean_spike(starthalfpk:endhalfpk);
    mean_halfpk_cent = mean_halfpk - mean(mean_halfpk);
    mean_halfpk_norm = mean_halfpk_cent ./ norm(mean_halfpk_cent);
    S = V * mean_halfpk_norm';
    A = sum(S .^ 2, 2);
    Err = sum(V .^ 2, 2) - A;
    snr = A ./ Err;
    mean_snr = median(snr);
    each_cv = std(halfpk) ./ mean(halfpk);
    cv = max(each_cv);
    mean_snr = sum(A ./ sum(V .^2, 2) < 0.7) / length(A);
end