%this file has been edited by Luis D. Davila and Alexander Friedman
function [the_cluster_data, supp_data] = extract_cluster_features_with_valley(the_raw_waveform_data,the_new_config,peak_pcs_file_name)
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

new_features = [];


peaks = get_peaks(the_raw_waveform_data, true);


if contains(the_new_config.which_new_feature,"valley_auc")
    valleys = get_peaks(the_raw_waveform_data*-1,true);
    new_features = [new_features;valleys];

end
if contains(the_new_config.which_new_feature, "velocity_based_features")
    smoothed_wf = smoothdata(the_raw_waveform_data,3,"movmedian",10,"omitmissing");
    % smoothed_wf = smoothdata(smoothed_wf,3);
    % the_velocities = diff(smoothed_wf,1,3);
    the_velocities = get_derivative_of_nonzero_parts_of_wf(smoothed_wf);
    aligned_velocities = align_to_peak(the_velocities * -1);
    the_velocity_peaks = get_peaks(aligned_velocities,true);
    new_features = [new_features;the_velocity_peaks];
end

if contains(the_new_config.which_new_feature,"prominance_and_peak_width")
    [peakProminence,peakWidthSeconds,peak_width_over_height] = get_peak_prominance_and_peak_width(the_raw_waveform_data,30:75);
    new_features = [peakProminence;peakWidthSeconds];

    if contains(the_new_config.which_new_feature,"width_over_height")
        new_features = [new_features;peak_width_over_height];
    end
end

if contains(the_new_config.which_new_feature,"trough")
    troughs = get_trough(the_raw_waveform_data);
    new_features = [new_features;troughs.'];
end

if contains(the_new_config.which_new_feature,"valley")
    valley_levels = get_valley(the_raw_waveform_data);
    new_features = [new_features;valley_levels];
end

if contains(the_new_config.which_new_feature,"first_valley")
    [peakProminence,peakWidthSeconds] = get_first_or_second_valley_features(the_raw_waveform_data*-1,1:46);
    new_features = [new_features;peakProminence;peakWidthSeconds];
end

if contains(the_new_config.which_new_feature,"second_valley")
    [peakProminence,peakWidthSeconds] = get_first_or_second_valley_features(the_raw_waveform_data*-1,48:size(the_raw_waveform_data,3));
    new_features = [new_features;peakProminence;peakWidthSeconds];
end

if contains(the_new_config.which_new_feature,"auc")
    [area_under_curve,area_over_curve ]= get_area_under_zero_line(the_raw_waveform_data,1:30);
    new_features = [new_features;area_under_curve];
    if contains(the_new_config.which_new_feature,"aoc")
        new_features = [new_features;area_over_curve];
    end
end


% plot_peaks(peaks.',"in extract cluster features.m",[])
if ~contains(the_new_config.which_new_feature,"without_pcs")
    num_peaks = size(peaks, 1);
    [~, peakpcs] = pca(peaks');
    %plot_pca_results(peakpcs);
    pcs = get_new_pcs(the_raw_waveform_data);
    pc1 = pcs(:, :, 1);
    pc2 = pcs(:, :, 2);

    the_cluster_data = [peaks ; pc1 ; peakpcs(:, 1:num_peaks-1)';new_features]';
else
    the_cluster_data = [peaks ;new_features]';
end
% y2 = reshape(the_raw_waveform_data,size(peaks,2),[]]);

if contains(the_new_config.which_new_feature,"peak_minus_valley")
    [~,~,valley_volt] = get_first_or_second_valley_features(the_raw_waveform_data*-1,48:size(the_raw_waveform_data,3));
    new_features = [new_features;peaks - valley_volt];
end

if contains(the_new_config.which_new_feature,"pca_only")
    [~,scores] = pca(the_cluster_data);
    the_cluster_data = scores;
end
if contains(the_new_config.which_new_feature,"pc_as_feature")
    [~,scores] = pca(the_cluster_data);
    the_cluster_data = [the_cluster_data,scores(size(the_raw_waveform_data,2):end)];
end

if contains(the_new_config.which_new_feature,"z_score")
    the_cluster_data = zscore(the_cluster_data);
end

supp_data = [];


end