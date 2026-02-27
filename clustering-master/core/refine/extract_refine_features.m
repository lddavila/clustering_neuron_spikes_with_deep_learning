%this file has been edited by Luis D. Davila and Alexander Friedman 
function the_features = extract_refine_features(the_spikes_aka_waveforms)
%EXTRACT_REFINE_FEATURES Extracts features for refinement.
%   features = EXTRACT_REFINE_FEATURES(spikes) returns the features used in
%   the refinement step of clustering.
%
%   'spikes' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%
%   In this case, the features are:
%   - Peaks (one for each wire)
%   - Principal Component 1 (one for each wire)
%
%   The features are also min-max normalized in groups to strip units and
%   thus unintentional weight for one feature versus another.

    peaks = get_peaks(the_spikes_aka_waveforms, true);
    pcs = get_new_pcs(the_spikes_aka_waveforms);
    pc1 = pcs(:, :, 1);

%     pcs = get_new_pcs(spikes, true);
%     pc1 = pcs(:, :, 1);
    
    the_features = zscore([peaks ; pc1]');
end