function representative_channel = get_representative_channels(bp)
%GET_REPRESENTATIVE_CHANNELS Read the physical representative channel.
%
% Some blind-pass tables save the representative channel in its own column.
% Older tables keep the channel list and representative-wire position inside
% grades. Both formats describe the same physical channel on the probe.

column_names = string(bp.Properties.VariableNames);
number_of_clusters = height(bp);

if ismember("rep_channel_1", column_names)
    representative_channel = bp{:, "rep_channel_1"};
    if iscell(representative_channel)
        representative_channel = cell2mat(representative_channel);
    end
    representative_channel = double(representative_channel(:));
    return
end

if ismember("grades", column_names)
    grade_column = bp{:, "grades"};
    representative_channel = nan(number_of_clusters, 1);

    for cluster_id = 1:number_of_clusters
        grades = grade_column{cluster_id};
        if iscell(grades) && isscalar(grades) && iscell(grades{1})
            grades = grades{1};
        end
        if ~iscell(grades) || numel(grades) < 49
            continue
        end

        channels = grades{49};
        representative_position = grades{42};
        if isnumeric(channels) && isnumeric(representative_position) && ...
                isscalar(representative_position) && ...
                isfinite(representative_position) && ...
                representative_position == round(representative_position) && ...
                representative_position >= 1 && ...
                representative_position <= numel(channels)
            representative_channel(cluster_id) = ...
                channels(representative_position);
        end
    end
    return
end

if ismember("rep_wire_1", column_names)
    representative_channel = bp{:, "rep_wire_1"};
    if iscell(representative_channel)
        representative_channel = cell2mat(representative_channel);
    end
    representative_channel = double(representative_channel(:));
    return
end

error("The table needs rep_channel_1, grades, or rep_wire_1.");
end
