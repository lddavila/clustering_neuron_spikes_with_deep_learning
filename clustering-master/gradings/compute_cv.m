%updated by Luis David Davila and Alexander Friedman
function the_calculated_cv = compute_cv(the_peaks)
%COMPUTE_CV Computes the cv of the cluster's representative wire's peak
%distribution.
%   cv = COMPUTE_CV(peaks)
    
    [~, rep_wire] = max(mean(the_peaks, 2));
    rep_peaks = the_peaks(rep_wire, :);
    the_calculated_cv = std(rep_peaks) / mean(rep_peaks);
end