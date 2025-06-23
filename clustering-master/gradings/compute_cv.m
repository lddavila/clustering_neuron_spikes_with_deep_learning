function cv = compute_cv(peaks)
%COMPUTE_CV Computes the cv of the cluster's representative wire's peak
%distribution.
%   cv = COMPUTE_CV(peaks)
    
    [~, rep_wire] = max(mean(peaks, 2));
    rep_peaks = peaks(rep_wire, :);
    cv = std(rep_peaks) / mean(rep_peaks);
end