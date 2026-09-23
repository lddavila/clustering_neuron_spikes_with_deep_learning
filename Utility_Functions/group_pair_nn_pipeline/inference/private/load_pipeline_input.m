function input = load_pipeline_input(bp_table_file)
%LOAD_PIPELINE_INPUT Load the table and find rows that can be compared.
%
% The complete ensemble matrix includes every row with usable timestamps,
% waveform data, and a valid representative wire. Spike count and accuracy
% are not checked here because those filters are applied after the complete
% matrix has been built.

loaded = load(bp_table_file, "data_to_save");
if ~isfield(loaded, "data_to_save") || ~istable(loaded.data_to_save)
    error("The MAT file must contain a table named data_to_save.");
end

bp = loaded.data_to_save;
column_names = string(bp.Properties.VariableNames);
required_columns = [
    "timestamps"
    "mean_waveform_rep_wire_1"
];

missing_columns = required_columns(~ismember(required_columns, column_names));
if ~isempty(missing_columns)
    error("The blind-pass table is missing: %s", ...
        strjoin(missing_columns, ", "));
end

number_of_clusters = height(bp);
timestamp_column = bp{:, "timestamps"};
waveform_column = bp{:, "mean_waveform_rep_wire_1"};
representative_channel = get_representative_channels(bp);

probe_locations = get_probe_xy();
valid_timestamp = false(number_of_clusters, 1);
valid_waveform = false(number_of_clusters, 1);
spike_count = zeros(number_of_clusters, 1);
waveform_length = NaN;

for cluster_id = 1:number_of_clusters
    timestamps = timestamp_column{cluster_id};
    if iscell(timestamps) && isscalar(timestamps)
        timestamps = timestamps{1};
    end
    valid_timestamp(cluster_id) = isnumeric(timestamps) && ...
        isvector(timestamps) && ~isempty(timestamps) && ...
        all(isfinite(timestamps));
    if valid_timestamp(cluster_id)
        spike_count(cluster_id) = numel(timestamps);
    end

    waveform = waveform_column{cluster_id};
    if iscell(waveform) && isscalar(waveform)
        waveform = waveform{1};
    end
    waveform_is_valid = isnumeric(waveform) && isvector(waveform) && ...
        ~isempty(waveform) && all(isfinite(waveform));

    if waveform_is_valid && isnan(waveform_length)
        waveform_length = numel(waveform);
    end
    valid_waveform(cluster_id) = waveform_is_valid && ...
        numel(waveform) == waveform_length;
end

valid_representative_channel = isfinite(representative_channel) & ...
    representative_channel == round(representative_channel) & ...
    representative_channel >= 1 & ...
    representative_channel <= size(probe_locations, 1);
valid_row = valid_timestamp & valid_waveform & ...
    valid_representative_channel;
valid_row_indices = find(valid_row);

if isempty(valid_row_indices)
    error("The blind-pass table does not contain any structurally valid rows.");
end

if ismember("recording_name", column_names)
    recording_value = bp{1, "recording_name"};
    if iscell(recording_value)
        recording_value = recording_value{1};
    end
    recording_name = string(recording_value);
else
    [parent_folder, ~, ~] = fileparts(bp_table_file);
    [~, recording_name] = fileparts(parent_folder);
    if recording_name == "blind_pass_table"
        [parent_folder, ~, ~] = fileparts(parent_folder);
        [~, recording_name] = fileparts(parent_folder);
    end
end

recording_name = regexprep(recording_name, "[^A-Za-z0-9_-]", "_");
if strlength(recording_name) == 0
    recording_name = "unnamed_recording";
end

fprintf("invalid timestamps:        %d\n", sum(~valid_timestamp));
fprintf("invalid waveforms:         %d\n", sum(~valid_waveform));
fprintf("invalid representative channel: %d\n", ...
    sum(~valid_representative_channel));
fprintf("rows excluded as unusable: %d\n", sum(~valid_row));

input.bp = bp;
input.recording_name = recording_name;
input.valid_row_indices = valid_row_indices;
input.spike_count = spike_count;
input.valid_row = valid_row;
input.representative_channel = representative_channel;
end
