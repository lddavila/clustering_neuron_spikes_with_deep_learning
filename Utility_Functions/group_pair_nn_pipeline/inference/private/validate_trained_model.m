function validate_trained_model(model)
%VALIDATE_TRAINED_MODEL Check the saved network and its feature information.

required_fields = [
    "final_net"
    "feature_names"
    "feature_mean"
    "feature_std"
    "probability_cutoff"
    "support_cutoff"
];

for field_id = 1:numel(required_fields)
    if ~isfield(model, required_fields(field_id))
        error("The trained model is missing %s.", required_fields(field_id));
    end
end

expected_features = [
    "small_timestamp_overlap"
    "large_timestamp_overlap"
    "matched_timestamps"
    "waveform_distance"
    "repwire_distance"
    "left_cluster_count"
    "right_cluster_count"
    "left_timestamp_count"
    "right_timestamp_count"
];

if ~isequal(string(model.feature_names(:)), expected_features)
    error("The trained model does not use the expected nine features.");
end

if numel(model.feature_mean) ~= 9 || numel(model.feature_std) ~= 9 || ...
        any(~isfinite(model.feature_mean)) || ...
        any(~isfinite(model.feature_std)) || any(model.feature_std == 0)
    error("The saved feature normalization values are invalid.");
end
end
