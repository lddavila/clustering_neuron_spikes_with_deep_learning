%edited by Luis David Davila and Alexander Friedman
function the_pmv = compute_snr_statistic(the_aligned, the_raw, the_tvals, the_ir)
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
p = get_peaks(the_aligned, true)';
nv = get_peaks(the_raw * (-1), false, the_tvals, the_ir)'; % Valleys

score = zscore(p + nv);
the_pmv = zscore(max(score, [], 2));

%new method which normalzies using the MAD version
% data_to_score = p + nv;
% % score = (data_to_score - median(data_to_score)) ./ (median(abs(data_to_score - median(data_to_score))) / 0.6745);
% data_to_normalize = max(score,[],2);
% the_pmv = median(abs(data_to_normalize - median(data_to_normalize))) / 0.6745;

% med_vals = median(data_to_score, 1);
% mad_vals = median(abs(data_to_score - med_vals), 1) / 0.6745;

% Avoid divide-by-zero
% mad_vals(mad_vals == 0) = eps;
% 
% score = (data_to_score - med_vals) ./ mad_vals;
% 
% % For each spike, take the best channel
% data_to_normalize = max(score, [], 2);
% 
% % Optional: robust normalize final per-spike values
% final_med = median(data_to_normalize);
% final_mad = median(abs(data_to_normalize - final_med)) / 0.6745;
% 
% if final_mad == 0
%     final_mad = eps;
% end

% the_pmv = (data_to_normalize - final_med) / final_mad;
end