function lratio = compute_lratio(peaks, other_peaks, dim)
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
    if isempty(other_peaks)
        lratio = 0;
        return
    end
    num_cluster_spikes = size(peaks, 1);
    numdims = size(peaks, 2);
    if nargin == 2
        dim = 1:numdims;
    end
    try
        dist = mahal(peaks(:, dim), other_peaks(:, dim));
    catch
        lratio = Inf;
        return
    end
    lratio = sum(1 - chi2cdf(dist, length(dim)))/num_cluster_spikes;
end