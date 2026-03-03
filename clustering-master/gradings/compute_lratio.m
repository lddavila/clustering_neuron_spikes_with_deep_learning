%updated by Luis David Davila and Alexander Friedman
function the_computed_lratio = compute_lratio(the_waveform_peaks, the_other_cluster_peaks, the_dim)
%COMPUTE_LRATIO Computes the LRatio between the cluster and the rest of the
%recording based on peaks.
%   lratio = compute_lratio(peaks, other_peaks) returns the lratio for all
%   dimensions of peaks and other_peaks.
%
%   lratio = compute_lratio(peaks, other_peaks, dim) returns the lratio for
%   the specified dimension of peaks and other_peaks.
%
%   The rows of 'peaks' and 'other_peaks' correspond to all of the peaks
%   for that particular spike (one for each wire).
%
%   'dim' is the wire or vector of wires to use instead of using all of
%   them.
%
%   See also RATE_CLUSTERS, COMPUTE_GRADINGS.
    if isempty(the_other_cluster_peaks)
        the_computed_lratio = 0;
        return
    end
    num_cluster_spikes = size(the_waveform_peaks, 1);
    numdims = size(the_waveform_peaks, 2);
    if nargin == 2
        the_dim = 1:numdims;
    end
    try
        %OG_LINE: dist = mahal(peaks(:, dim), other_peaks(:, dim));
        dist = mahal_fixed_for_num_unstable(the_waveform_peaks(:, the_dim), the_other_cluster_peaks(:, the_dim));
    catch
        the_computed_lratio = Inf;
        return
    end
    the_computed_lratio = sum(1 - chi2cdf(dist, length(the_dim)))/num_cluster_spikes;
end