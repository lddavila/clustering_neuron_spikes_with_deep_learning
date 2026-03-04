%edited by Luis David Davila and Alexander Friedman
function the_idx = extract_clusters_from_output(the_timestamps, the_output_data, the_config)
%EXTRACT_CLUSTERS_FROM_OUTPUT Converts the standard output format of spike
%sorting into a format that's easier to work with (a cell array of indices
%for each cluster).
%   idx = EXTRACT_CLUSTERS_FROM_OUTPUT(timestamps, output)
%
%   'timestamps' are the timestamps for each spike in seconds.
%
%   'output' is the standardized output format.
%   - the first column contains the timestamps of the spikes in seconds
%   - the second column contains the cluster classification of the spikes
%       E.g., a value of '3' means that the spike belongs to cluster 3.
%
%   'idx' is a cell array of indices for each cluster.

    ids = unique(the_output_data(:, 2));
    ids = sort(ids(ids > 0));
    the_idx = cell(length(ids), 1);
    for k = 1:length(ids)
        cluster_timestamps = the_output_data(the_output_data(:, 2) == ids(k), 1);
        the_idx{k} = get_idx_from_timestamps(the_timestamps, cluster_timestamps);
        % if length(idx{k}) < config.MIN_NUMBER_OF_SPIKES
        %     idx{k} = [];
        % end
    end
    the_idx = the_idx(~cellfun('isempty', the_idx));
end