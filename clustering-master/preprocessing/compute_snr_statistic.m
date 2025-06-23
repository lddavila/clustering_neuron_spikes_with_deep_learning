function pmv = compute_snr_statistic(aligned, raw, tvals, ir)
%COMPUTE_SNR_STATISTIC Computes an SNR statistic for each spike which
%corresponds to the maximum difference between peak and valley across the
%four channels, divided by their threshold values so that it is a fair
%comparison.
%
%Note: currently zscore normalized instead of dividing by threshold.
%   pmv = COMPUTE_SNR_STATISTIC(aligned, raw, tvals, ir)
%
%   'aligned' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It is the same as 'raw', but with spikes aligned to have the same peak
%   index.
%
%   'raw' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It represents the raw spike samples recorded.
%
%   'tvals' are the threshold values for each wire in microvolts.
%
%   'ir' are the input range values for each wire in microvolts.

    p = get_peaks(aligned, true)';
    nv = get_peaks(raw * (-1), false, tvals, ir)'; % Valleys
    
    score = zscore(p + nv);
    pmv = zscore(max(score, [], 2));
end