function [cluster_data, supp_data] = extract_cluster_features(raw)
%EXTRACT_CLUSTER_FEATURES Extracts features from the spike waveforms.
%   [cluster_data, supp_data] = EXTRACT_CLUSTER_FEATURES(raw) returns two
%   sets of features:
%   - 'cluster_data' are necessary features for clustering
%   - 'supp_data' are supplementary features for clustering
%   
%   'raw' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%
%   The distinction between necessary and supplementary features only
%   exists because we have some prior knowledge of which types of features
%   tend to be more important, as well as which types of features tend to
%   sometimes mislead.
%
%   The necessary features are:
%   - Peaks (one feature for each wire)
%   - Principal Component 1 (one feature for each wire)
%
%   The supplementary features are:
%   - Principal Component 2 (one feature for each wire)
%   - Principal Components of Peaks (n-1 features, where n is the number of
%   wires)
%
%   In addition to extracting the features, it also performs zscore
%   normalization on each feature in an effort to strip units, thereby
%   making each feature comparable in the clustering algorithm.
%
%   See also GET_PEAKS, PCA, GET_NEW_PCS.
    peaks = get_peaks(raw, true);
   % plot_peaks(peaks.',"in extract cluster features.m",[])
    num_peaks = size(peaks, 1);
    [~, peakpcs] = pca(peaks');
   %plot_pca_results(peakpcs);
    pcs = get_new_pcs(raw);
    pc1 = pcs(:, :, 1);
%     pc2 = pcs(:, :, 2);
%     pcs = get_new_pcs(raw, true);
%     pc1 = pcs(:, :, 1);
    
    cluster_data = zscore([peaks ; pc1 ; peakpcs(:, 1:num_peaks-1)']'); % OG LINE
     cluster_data = [peaks ; pc1 ; peakpcs(:, 1:num_peaks-1)']'; % OG LINE
   % cluster_data = zscore(peaks); %new line with pcs remsoved
%     supp_data = zscore(pc2');
    supp_data = [];
    
end