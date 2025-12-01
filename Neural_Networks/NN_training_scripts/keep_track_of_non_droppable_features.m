function [] = keep_track_of_non_droppable_features(feature_idx)
persistent features_to_never_remove
if isempty(feature_idx)
    features_to_never_remove = [];
elseif ~isnan(feature_idx) && ~isempty(feature_idx)
    if any(~ismember(feature_idx,features_to_never_remove))
        features_to_never_remove = union(features_to_never_remove,feature_idx);
    end
end

end